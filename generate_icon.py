#!/usr/bin/env python3
"""Generate anycard app icon - blue card with diagonal stripe"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_app_icon(size=1024):
    # Create image with gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient (blue)
    for y in range(size):
        # Gradient from #007AFF to #5856D6
        ratio = y / size
        r = int(0 + (88 - 0) * ratio)
        g = int(122 + (86 - 122) * ratio)
        b = int(255 + (214 - 255) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Card dimensions
    margin = size * 0.15
    card_width = size - 2 * margin
    card_height = card_width * 0.63  # Credit card ratio
    card_x = margin
    card_y = (size - card_height) / 2
    
    # Card shadow
    shadow_offset = size * 0.02
    draw.rounded_rectangle(
        [card_x + shadow_offset, card_y + shadow_offset, 
         card_x + card_width + shadow_offset, card_y + card_height + shadow_offset],
        radius=size * 0.05,
        fill=(0, 0, 0, 80)
    )
    
    # Card background (dark)
    draw.rounded_rectangle(
        [card_x, card_y, card_x + card_width, card_y + card_height],
        radius=size * 0.05,
        fill=(28, 28, 30)
    )
    
    # Diagonal stripe (accent color)
    stripe_width = card_width * 0.15
    # Draw diagonal stripe from bottom-left to top-right area
    stripe_points = [
        (card_x + card_width * 0.1, card_y + card_height),
        (card_x + card_width * 0.1 + stripe_width, card_y + card_height),
        (card_x + card_width * 0.4 + stripe_width, card_y),
        (card_x + card_width * 0.4, card_y),
    ]
    
    # Create mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [card_x, card_y, card_x + card_width, card_y + card_height],
        radius=size * 0.05,
        fill=255
    )
    
    # Draw stripe on separate layer
    stripe_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    stripe_draw = ImageDraw.Draw(stripe_layer)
    stripe_draw.polygon(stripe_points, fill=(0, 122, 255))  # Blue accent
    
    # Apply mask to stripe
    stripe_layer.putalpha(Image.composite(stripe_layer.split()[3], Image.new('L', (size, size), 0), mask))
    
    # Composite stripe onto main image
    img = Image.alpha_composite(img, stripe_layer)
    draw = ImageDraw.Draw(img)
    
    # Barcode lines (simplified)
    barcode_y = card_y + card_height * 0.65
    barcode_height = card_height * 0.2
    barcode_x_start = card_x + card_width * 0.15
    barcode_x_end = card_x + card_width * 0.85
    
    # Draw barcode lines
    line_x = barcode_x_start
    while line_x < barcode_x_end:
        line_width = (hash(str(line_x)) % 3 + 1) * (size * 0.005)
        gap = (hash(str(line_x + 1)) % 2 + 1) * (size * 0.005)
        draw.rectangle(
            [line_x, barcode_y, line_x + line_width, barcode_y + barcode_height],
            fill=(255, 255, 255)
        )
        line_x += line_width + gap
    
    return img

def main():
    # Generate 1024x1024 icon
    icon = create_app_icon(1024)
    
    # Save
    output_path = '/tmp/anycard/anycard/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    icon.save(output_path, 'PNG')
    print(f'Saved: {output_path}')
    
    # Update Contents.json
    contents = '''{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}'''
    
    contents_path = '/tmp/anycard/anycard/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json'
    with open(contents_path, 'w') as f:
        f.write(contents)
    print(f'Updated: {contents_path}')

if __name__ == '__main__':
    main()
