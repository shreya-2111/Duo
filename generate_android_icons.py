import os
from PIL import Image, ImageDraw

base_dir = r"d:\Duo"
icon_path = os.path.join(base_dir, "DUO_Logos", "PNG", "DUO_icon-only.png")
vertical_path = os.path.join(base_dir, "DUO_Logos", "PNG", "DUO_vertical.png")
res_dir = os.path.join(base_dir, "mobile", "android", "app", "src", "main", "res")

src_icon = Image.open(icon_path).convert("RGBA")

# Mipmap densities and standard icon sizes
densities = {
    "mipmap-mdpi": (48, 108),
    "mipmap-hdpi": (72, 162),
    "mipmap-xhdpi": (96, 216),
    "mipmap-xxhdpi": (144, 324),
    "mipmap-xxxhdpi": (192, 432),
}

# 1. Generate Adaptive Foreground Icons (108dp canvas, safe zone ~66dp)
for folder, (std_size, adapt_size) in densities.items():
    folder_path = os.path.join(res_dir, folder)
    os.makedirs(folder_path, exist_ok=True)
    
    # Adaptive foreground: transparent canvas of adapt_size
    fg = Image.new("RGBA", (adapt_size, adapt_size), (0, 0, 0, 0))
    # Target size for the icon inside safe zone (approx 62% of canvas)
    target_icon_size = int(adapt_size * 0.62)
    resized_icon = src_icon.resize((target_icon_size, target_icon_size), Image.Resampling.LANCZOS)
    
    offset = ((adapt_size - target_icon_size) // 2, (adapt_size - target_icon_size) // 2)
    fg.paste(resized_icon, offset, resized_icon)
    fg.save(os.path.join(folder_path, "ic_launcher_foreground.png"), "PNG")
    
    # 2. Standard Legacy Launcher Icon (std_size with rounded squircle on #FFFFFF)
    legacy = Image.new("RGBA", (std_size, std_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(legacy)
    corner_radius = int(std_size * 0.22)
    # Background squircle
    draw.rounded_rectangle([1, 1, std_size - 2, std_size - 2], radius=corner_radius, fill=(255, 255, 255, 255), outline=(220, 206, 255, 255), width=max(1, int(std_size * 0.03)))
    
    # Place icon inside
    icon_inner_size = int(std_size * 0.74)
    inner_resized = src_icon.resize((icon_inner_size, icon_inner_size), Image.Resampling.LANCZOS)
    inner_offset = ((std_size - icon_inner_size) // 2, (std_size - icon_inner_size) // 2)
    legacy.paste(inner_resized, inner_offset, inner_resized)
    legacy.save(os.path.join(folder_path, "ic_launcher.png"), "PNG")

    # 3. Round Launcher Icon (circular)
    round_icon = Image.new("RGBA", (std_size, std_size), (0, 0, 0, 0))
    draw_round = ImageDraw.Draw(round_icon)
    draw_round.ellipse([1, 1, std_size - 2, std_size - 2], fill=(255, 255, 255, 255), outline=(220, 206, 255, 255), width=max(1, int(std_size * 0.03)))
    round_icon.paste(inner_resized, inner_offset, inner_resized)
    round_icon.save(os.path.join(folder_path, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder}: std={std_size}x{std_size}, adapt={adapt_size}x{adapt_size}")

# 4. Generate Native Splash Image (drawable/launch_image.png)
drawable_dir = os.path.join(res_dir, "drawable")
os.makedirs(drawable_dir, exist_ok=True)
splash_img = src_icon.resize((240, 240), Image.Resampling.LANCZOS)
splash_img.save(os.path.join(drawable_dir, "launch_image.png"), "PNG")
print("Generated drawable/launch_image.png (240x240)")

print("Android icon generation completed successfully.")

