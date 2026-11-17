from PIL import Image, ImageDraw, ImageFont
import os

def create_wizard_banner():
    w, h = 164, 314
    img = Image.new('RGB', (w, h), (8, 20, 8))
    draw = ImageDraw.Draw(img)
    
    # Gradient background
    for y in range(h):
        t = y / h
        r = int(8 + t * 4)
        g = int(20 + t * 15)
        b = int(8 + t * 4)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    
    # Green glow orb in center
    for radius in range(80, 10, -8):
        alpha_val = int(255 * (1 - radius/80) * 0.3)
        glow_color = (0, int(alpha_val * 0.8), 0)
        draw.ellipse([w//2 - radius, h//2 - radius, w//2 + radius, h//2 + radius],
                     outline=glow_color)
    
    # Cart icon in center
    cx, cy = w//2, h//2 - 10
    # Cart body
    draw.rectangle([cx-28, cy-18, cx+28, cy+14], outline=(76, 175, 80), width=3)
    # Cart handle
    draw.line([cx-38, cy-8, cx-28, cy-8], fill=(76, 175, 80), width=3)
    draw.line([cx-38, cy-18, cx-38, cy-8], fill=(76, 175, 80), width=3)
    # Wheels
    draw.ellipse([cx-22, cy+14, cx-10, cy+26], outline=(76, 175, 80), width=2)
    draw.ellipse([cx+10, cy+14, cx+22, cy+26], outline=(76, 175, 80), width=2)
    # $ in cart
    try:
        font_lg = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 20)
        font_title = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 14)
        font_sub = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 10)
    except:
        font_lg = font_title = font_sub = ImageFont.load_default()
    
    draw.text((cx - 7, cy - 10), "$", fill=(129, 199, 132), font=font_lg)
    
    # Title text
    draw.text((w//2 - 38, 30), "FRESH", fill=(76, 175, 80), font=font_title)
    draw.text((w//2 - 32, 48), "MART", fill=(76, 175, 80), font=font_title)
    
    # Version
    draw.text((w//2 - 18, h - 50), "v7.0", fill=(100, 160, 100), font=font_sub)
    draw.text((w//2 - 32, h - 36), "Godot 4", fill=(80, 130, 80), font=font_sub)
    
    # Side accent lines
    for i in range(0, h, 20):
        alpha = int(30 + 20 * abs((i % 40) / 40.0 - 0.5))
        draw.line([(0, i), (3, i)], fill=(0, alpha, 0))
        draw.line([(w-3, i), (w, i)], fill=(0, alpha, 0))
    
    out = r"C:\Users\m\OneDrive\Desktop\fresh-mart\installer\wizard_assets\wizard_banner.bmp"
    img.save(out, 'BMP')
    print(f"Banner: {out} ({os.path.getsize(out)} bytes)")

def create_wizard_small():
    w, h = 55, 55
    img = Image.new('RGB', (w, h), (8, 20, 8))
    draw = ImageDraw.Draw(img)
    
    # Background gradient
    for y in range(h):
        t = y / h
        draw.line([(0, y), (w, y)], fill=(int(8+t*5), int(18+t*18), int(8+t*5)))
    
    # Mini cart
    cx, cy = w//2, h//2
    draw.rectangle([cx-14, cy-8, cx+14, cy+5], outline=(76, 175, 80), width=2)
    draw.line([cx-19, cy-3, cx-14, cy-3], fill=(76, 175, 80), width=2)
    draw.line([cx-19, cy-8, cx-19, cy-3], fill=(76, 175, 80), width=2)
    draw.ellipse([cx-11, cy+5, cx-5, cy+11], outline=(76, 175, 80), width=1)
    draw.ellipse([cx+5, cy+5, cx+11, cy+11], outline=(76, 175, 80), width=1)
    
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 9)
        draw.text((cx - 4, cy - 5), "$", fill=(129, 199, 132), font=font)
    except:
        pass
    
    out = r"C:\Users\m\OneDrive\Desktop\fresh-mart\installer\wizard_assets\wizard_small.bmp"
    img.save(out, 'BMP')
    print(f"Small: {out} ({os.path.getsize(out)} bytes)")

create_wizard_banner()
create_wizard_small()
print("Done!")
