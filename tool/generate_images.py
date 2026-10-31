#!/usr/bin/env python3
"""Genera las fotos de producto con fondo transparente usando la API de imágenes
de OpenAI (el mismo modelo que usa Codex para crear imágenes).

    export OPENAI_API_KEY=...            # nunca la subas al repo
    python3 tool/generate_images.py      # genera solo las que faltan
    python3 tool/generate_images.py --only shishas-zeus copas-ron --force

Si las imágenes se crean con otra herramienta (p. ej. Codex), guárdalas como
PNG transparentes con el nombre de su clave (`<clave>.png`) y procésalas:

    python3 tool/generate_images.py --import tool/raw

Salida: assets/products/<clave>.webp (512 px, recortadas al contenido) y
lib/data/product_images.g.dart con las claves disponibles.
Requiere Pillow (pip install pillow).
"""

import argparse
import base64
import io
import json
import os
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "tool" / "image_prompts.json"
OUT = ROOT / "assets" / "products"
INDEX = ROOT / "lib" / "data" / "product_images.g.dart"

STYLE = (
    "Hyperrealistic 3D product render that looks like a photo: glossy, ultra-detailed, "
    "vivid saturated colours, juicy specular highlights, for a premium dark-themed lounge menu app. "
    "Straight-on front view at eye level, single subject centered, filling most of the frame. "
    "Dark, high-contrast low-key lighting: strong key light from one side, deep shadows on the subject, "
    "crisp bright rim light outlining the edges. "
    "Isolated on a fully transparent background: no backdrop, no table surface, no ground shadow, "
    "no text, no logos, no brand labels."
)


def generate(key: str, subject: str, model: str, quality: str) -> bytes:
    body = json.dumps({
        "model": model,
        "prompt": f"{subject}. {STYLE}",
        "size": "1024x1024",
        "quality": quality,
        "background": "transparent",
        "output_format": "png",
        "n": 1,
    }).encode()
    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations",
        data=body,
        headers={
            "Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            data = json.load(r)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{key}: HTTP {e.code} {e.read().decode(errors='replace')[:300]}") from e
    return base64.b64decode(data["data"][0]["b64_json"])


def clean_edges(img: Image.Image) -> None:
    """El generador recorta a cuchillo (alfa 0/≈255) y deja un halo del fondo:
    se come 1 px del borde y se suaviza el contorno para que no haga sierra."""
    a = img.getchannel("A")
    solid = a.point(lambda v: 255 if v > 128 else 0)
    soft = solid.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(2.6))
    soft = soft.point(lambda v: max(0, min(255, int((v - 128) * 1.8 + 128))))
    # Conserva la translucidez que sí traiga la imagen (cristal, humo).
    img.putalpha(ImageChops.multiply(soft, a.point(lambda v: min(255, v * 255 // 250))))


def glass_translucency(img: Image.Image) -> None:
    """El generador deja opaco el cristal de la cachimba. En la mitad inferior,
    los grises medios poco saturados (el vaso) pasan a semitransparentes para
    que se vean las frutas de detrás; el metal negro y los brillos se quedan."""
    w, h = img.size
    hsv = img.convert("RGB").convert("HSV")
    mask = Image.new("L", img.size, 255)
    px, hv = mask.load(), hsv.load()
    for y in range(int(h * 0.58), h):
        for x in range(w):
            _, s, v = hv[x, y]
            if 50 < v < 215 and s < 90:
                px[x, y] = 120
    mask = mask.filter(ImageFilter.GaussianBlur(3))
    img.putalpha(ImageChops.multiply(img.getchannel("A"), mask))


def save(key: str, png: bytes) -> None:
    img = Image.open(io.BytesIO(png)).convert("RGBA")
    if img.getchannel("A").getextrema()[0] == 255:
        print(f"  ! {key}: la imagen no trae transparencia", file=sys.stderr)
    clean_edges(img)
    if key == "shisha-cachimba":
        glass_translucency(img)
    bbox = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)
    # Cuadrado con un pequeño margen, apoyado abajo (se ve "posado" sobre el arco).
    side = int(max(img.size) * 1.06)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - img.width) // 2, side - img.height - int(side * 0.02)), img)
    canvas = canvas.resize((512, 512), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT / f"{key}.webp", "WEBP", quality=86, method=6)


def write_index() -> None:
    keys = sorted(p.stem for p in OUT.glob("*.webp"))
    lines = ",\n".join(f"  '{k}'" for k in keys)
    INDEX.write_text(
        "// Generado por tool/generate_images.py. No editar a mano.\n\n"
        "/// Fotos de producto disponibles en `assets/products/`.\n"
        f"const productImages = <String>{{\n{lines}{',' if keys else ''}\n}};\n"
    )
    print(f"{len(keys)} imágenes en {OUT.relative_to(ROOT)}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", help="claves concretas")
    ap.add_argument("--force", action="store_true", help="regenerar aunque exista")
    ap.add_argument("--model", default=os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1"))
    ap.add_argument("--quality", default="medium", choices=["low", "medium", "high"])
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--index-only", action="store_true", help="solo regenerar el índice Dart")
    ap.add_argument("--import", dest="import_dir", help="procesar PNG ya generados (<clave>.png)")
    args = ap.parse_args()

    if args.index_only:
        return write_index()
    if args.import_dir:
        prompts = json.loads(PROMPTS.read_text())
        for f in sorted(Path(args.import_dir).glob("*.png")):
            if f.stem not in prompts:
                print(f"  ? {f.name}: clave desconocida, se ignora", file=sys.stderr)
                continue
            save(f.stem, f.read_bytes())
            print(f"  ✓ {f.stem}")
        missing = [k for k in prompts if not (OUT / f"{k}.webp").exists()]
        if missing:
            print(f"Faltan {len(missing)}: {' '.join(missing)}")
        return write_index()
    if "OPENAI_API_KEY" not in os.environ:
        sys.exit("Falta OPENAI_API_KEY en el entorno.")

    prompts = json.loads(PROMPTS.read_text())
    keys = args.only or list(prompts)
    todo = [k for k in keys if args.force or not (OUT / f"{k}.webp").exists()]
    print(f"Generando {len(todo)} de {len(keys)} con {args.model} ({args.quality})…")

    def job(k: str) -> str | None:
        try:
            save(k, generate(k, prompts[k], args.model, args.quality))
            print(f"  ✓ {k}")
        except Exception as e:  # noqa: BLE001 - seguimos con el resto
            print(f"  ✗ {e}", file=sys.stderr)
            return k
        return None

    with ThreadPoolExecutor(args.workers) as ex:
        failed = [k for k in ex.map(job, todo) if k]
    write_index()
    if failed:
        sys.exit(f"Fallaron {len(failed)}: {' '.join(failed)}")


if __name__ == "__main__":
    main()
