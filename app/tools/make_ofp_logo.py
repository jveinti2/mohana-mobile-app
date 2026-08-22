"""Genera assets/images/logo_ofp.png (RGBA) a partir del JPEG con fondo #F7F7F7.

El logo original de la Organización Femenina Popular viene en JPEG, formato que
no admite transparencia: sobre el fondo tonal de la app se veía como un
rectángulo casi blanco. Este script recorta ese fondo y deja el logo con canal
alfa, descontaminando el color de los píxeles de borde para no dejar halo.

Uso:  python tools/make_ofp_logo.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/images/logo_ofp.jpeg"
DST = ROOT / "assets/images/logo_ofp.png"
PREVIEW = ROOT / "build/logo_ofp_preview.png"  # comprobación visual, no se versiona

BG = np.array([247, 247, 247], dtype=np.float32)  # fondo uniforme del JPEG
LO, HI = 10.0, 45.0  # rampa de alfa según la distancia RGB al fondo
TARGET_H = 192  # 48 dp x4 -> nítido en pantallas 3x/4x
CHECK_BG = (212, 163, 214)  # MohanaColors.tonalTop, para la vista previa


def main() -> None:
    rgb = np.asarray(Image.open(SRC).convert("RGB"), dtype=np.float32)

    # 1) Alfa: 0 en el fondo, 1 en la tinta, rampa suave en los bordes.
    #    LO absorbe el ruido de compresión JPEG del fondo; HI deja ~35 niveles
    #    de antialias sin comerse los trazos finos de la tipografía.
    dist = np.sqrt(((rgb - BG) ** 2).sum(axis=-1))
    alpha = np.clip((dist - LO) / (HI - LO), 0.0, 1.0)
    a = alpha[..., None]

    # 2) Descontaminación: deshace la mezcla con el fondo en los píxeles de
    #    borde (src = fg*a + bg*(1-a)). Sin esto queda un halo claro.
    pure = np.where(a > 0.02, (rgb - BG * (1.0 - a)) / np.maximum(a, 1e-6), 0.0)
    pure = np.clip(pure, 0.0, 255.0)

    out = Image.fromarray(np.dstack([pure, alpha * 255.0]).astype(np.uint8), "RGBA")

    # 3) Recorte por el canal alfa (out.getbbox() no sirve: el RGB no es 0).
    out = out.crop(out.getchannel("A").getbbox())

    # 4) Reescalado a la resolución de trabajo.
    w, h = out.size
    out = out.resize((round(w * TARGET_H / h), TARGET_H), Image.LANCZOS)
    out.save(DST, optimize=True)

    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", out.size, CHECK_BG + (255,))
    Image.alpha_composite(canvas, out).save(PREVIEW)
    print(f"OK  {DST}  {out.size}   preview -> {PREVIEW}")


if __name__ == "__main__":
    main()
