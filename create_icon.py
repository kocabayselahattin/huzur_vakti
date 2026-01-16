# Uygulama İkonu Oluşturma Scripti
# Python ve Pillow kütüphanesi gerektirir: pip install pillow

from PIL import Image, ImageDraw, ImageFont
import math

def create_app_icon():
    # 1024x1024 boyutunda ikon (tüm platformlar için yeterli)
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Arka plan - Koyu mavi gradient efekti
    center = size // 2
    for i in range(center):
        # Dıştan içe gradient
        ratio = i / center
        r = int(27 + (43 - 27) * ratio)  # 1B -> 2B
        g = int(39 + (49 - 39) * ratio)  # 27 -> 31
        b = int(65 + (81 - 65) * ratio)  # 41 -> 51
        
        # Daire çiz
        draw.ellipse([i, i, size - i, size - i], fill=(r, g, b, 255))
    
    # Hilal (Ay) - Huzur Vakti için uygun sembol
    moon_color = (0, 188, 212, 255)  # Cyan
    
    # Dış daire (ay)
    moon_x, moon_y = center - 50, center - 100
    moon_radius = 180
    draw.ellipse(
        [moon_x - moon_radius, moon_y - moon_radius, 
         moon_x + moon_radius, moon_y + moon_radius],
        fill=moon_color
    )
    
    # İç daire (hilali oluşturmak için)
    inner_offset = 100
    draw.ellipse(
        [moon_x - moon_radius + inner_offset - 30, moon_y - moon_radius + 20,
         moon_x + moon_radius + inner_offset - 30, moon_y + moon_radius + 20],
        fill=(43, 49, 81, 255)  # Arka plan rengi
    )
    
    # Yıldızlar
    star_color = (255, 255, 255, 200)
    star_positions = [
        (center + 100, center - 150, 15),
        (center + 180, center - 80, 10),
        (center + 150, center + 20, 8),
        (center - 180, center + 100, 12),
        (center - 120, center + 180, 10),
    ]
    
    for sx, sy, sr in star_positions:
        # 4 köşeli yıldız
        points = []
        for i in range(8):
            angle = math.radians(i * 45 - 22.5)
            r = sr if i % 2 == 0 else sr * 0.4
            px = sx + r * math.cos(angle)
            py = sy + r * math.sin(angle)
            points.append((px, py))
        draw.polygon(points, fill=star_color)
    
    # Alt kısımda "مسجد" veya cami silueti benzeri
    # Basit cami kubbesi
    dome_y = center + 150
    dome_width = 200
    dome_height = 120
    
    # Kubbe
    draw.ellipse(
        [center - dome_width//2, dome_y - dome_height,
         center + dome_width//2, dome_y + dome_height//3],
        fill=(0, 188, 212, 180)
    )
    
    # Minare (sol)
    minare_w = 25
    draw.rectangle(
        [center - dome_width//2 - minare_w - 20, dome_y - 80,
         center - dome_width//2 - 20, dome_y + 80],
        fill=(0, 188, 212, 150)
    )
    
    # Minare (sağ)
    draw.rectangle(
        [center + dome_width//2 + 20, dome_y - 80,
         center + dome_width//2 + minare_w + 20, dome_y + 80],
        fill=(0, 188, 212, 150)
    )
    
    # Kaydet
    img.save('assets/icon/app_icon.png', 'PNG')
    print("Ana ikon oluşturuldu: assets/icon/app_icon.png")
    
    # Foreground ikon (adaptive ikon için)
    fg_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg_img)
    
    # Aynı hilal ve yıldızları çiz (arka plan olmadan)
    # Hilal
    fg_draw.ellipse(
        [moon_x - moon_radius, moon_y - moon_radius, 
         moon_x + moon_radius, moon_y + moon_radius],
        fill=moon_color
    )
    fg_draw.ellipse(
        [moon_x - moon_radius + inner_offset - 30, moon_y - moon_radius + 20,
         moon_x + moon_radius + inner_offset - 30, moon_y + moon_radius + 20],
        fill=(0, 0, 0, 0)  # Şeffaf
    )
    
    # Yıldızlar
    for sx, sy, sr in star_positions:
        points = []
        for i in range(8):
            angle = math.radians(i * 45 - 22.5)
            r = sr if i % 2 == 0 else sr * 0.4
            px = sx + r * math.cos(angle)
            py = sy + r * math.sin(angle)
            points.append((px, py))
        fg_draw.polygon(points, fill=star_color)
    
    # Kubbe ve minareler
    fg_draw.ellipse(
        [center - dome_width//2, dome_y - dome_height,
         center + dome_width//2, dome_y + dome_height//3],
        fill=(0, 188, 212, 220)
    )
    fg_draw.rectangle(
        [center - dome_width//2 - minare_w - 20, dome_y - 80,
         center - dome_width//2 - 20, dome_y + 80],
        fill=(0, 188, 212, 200)
    )
    fg_draw.rectangle(
        [center + dome_width//2 + 20, dome_y - 80,
         center + dome_width//2 + minare_w + 20, dome_y + 80],
        fill=(0, 188, 212, 200)
    )
    
    fg_img.save('assets/icon/app_icon_foreground.png', 'PNG')
    print("Foreground ikon oluşturuldu: assets/icon/app_icon_foreground.png")

if __name__ == "__main__":
    create_app_icon()
