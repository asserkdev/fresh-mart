from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    sizes = [256, 128, 64, 48, 32, 16]
    images = []

    for size in sizes:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Dark green rounded background
        margin = max(1, size // 16)
        draw.rounded_rectangle(
            [margin, margin, size - margin, size - margin],
            radius=max(2, size // 8),
            fill=(15, 30, 15, 255)
        )

        # Cart body
        s = size
        # Cart basket
        bx1 = int(s * 0.18)
        by1 = int(s * 0.22)
        bx2 = int(s * 0.82)
        by2 = int(s * 0.62)
        draw.rectangle([bx1, by1, bx2, by2], outline=(76, 175, 80, 255), width=max(1, s//20))

        # Cart handle
        hx1 = int(s * 0.08)
        hy = int(s * 0.32)
        hx2 = int(s * 0.18)
        draw.line([hx1, hy, hx2, hy], fill=(76, 175, 80, 255), width=max(1, s//20))
        draw.line([hx1, int(s*0.22), hx1, hy], fill=(76, 175, 80, 255), width=max(1, s//20))

        # Cart wheels
        wr = max(2, s // 12)
        wx1 = int(s * 0.30)
        wx2 = int(s * 0.68)
        wy = int(s * 0.72)
        draw.ellipse([wx1-wr, wy-wr, wx1+wr, wy+wr], outline=(76, 175, 80, 255), width=max(1, s//24))
        draw.ellipse([wx2-wr, wy-wr, wx2+wr, wy+wr], outline=(76, 175, 80, 255), width=max(1, s//24))

        # Dollar sign inside cart
        cx = s // 2
        cy = int(s * 0.42)
        font_size = max(8, s // 4)
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", font_size)
        except:
            font = ImageFont.load_default()

        bbox = draw.textbbox((0, 0), "$", font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((cx - tw//2, cy - th//2), "$", fill=(129, 199, 132, 255), font=font)

        # "FM" / "FRESH MART" text at bottom for larger sizes
        if size >= 48:
            fm_size = max(6, size // 7)
            try:
                fm_font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", fm_size)
            except:
                fm_font = ImageFont.load_default()
            label = "FRESH MART" if size >= 128 else "FM"
            bbox2 = draw.textbbox((0, 0), label, font=fm_font)
            tw2 = bbox2[2] - bbox2[0]
            draw.text((s//2 - tw2//2, int(s * 0.84)), label, fill=(200, 230, 200, 255), font=fm_font)

        images.append(img)

    base = r"C:\Users\m\OneDrive\Desktop\fresh-mart\assets\icons"

    # Save ICO
    ico_path = os.path.join(base, "icon.ico")
    images[0].save(
        ico_path,
        format='ICO',
        sizes=[(img.width, img.height) for img in images],
        append_images=images[1:]
    )
    print(f"ICO created : {ico_path}")
    print(f"ICO size    : {os.path.getsize(ico_path):,} bytes")

    # Save PNG (256x256)
    png_path = os.path.join(base, "icon.png")
    images[0].save(png_path, format='PNG')
    print(f"PNG created : {png_path}")
    print(f"PNG size    : {os.path.getsize(png_path):,} bytes")

create_icon()
