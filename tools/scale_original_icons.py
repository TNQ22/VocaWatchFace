import os
from PIL import Image

def scale_original_icons():
    # Load original 14x14 icons from commit 7492450 and scale them cleanly to 16x16
    for name in ['icon_alarm.png', 'icon_moon.png', 'icon_headphone.png', 'icon_phone_bt.png', 'icon_footprints.png']:
        path = os.path.join('resources/drawables', name)
        im = Image.open(path)
        bbox = im.getbbox()
        cropped = im.crop(bbox)
        cw, ch = cropped.size
        target_size = 16
        scale = min(target_size / cw, target_size / ch)
        nw, nh = int(round(cw * scale)), int(round(ch * scale))
        resized = cropped.resize((nw, nh), Image.Resampling.BILINEAR)
        
        res_img = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
        ox = (target_size - nw) // 2
        oy = (target_size - nh) // 2
        
        for y in range(nh):
            for x in range(nw):
                r, g, b, a = resized.getpixel((x, y))
                if a > 80:
                    res_img.putpixel((ox + x, oy + y), (r, g, b, 255))
                    
        res_img.save(path)
        print(f'Scaled {name} to 16x16 preserving original shape.')

if __name__ == '__main__':
    scale_original_icons()
