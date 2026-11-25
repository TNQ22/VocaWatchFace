import os
from PIL import Image, ImageFont, ImageDraw


def generate_bmfont(name: str, font_path: str, font_size: int, tex_w: int = 256, tex_h: int = 384):
    os.makedirs('resources/fonts', exist_ok=True)

    font = ImageFont.truetype(font_path, font_size)
    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    base = ascent

    # English IPA and phonetic characters
    ipa_chars = [
        '\u02c8', # ˈ primary stress
        '\u02cc', # ˌ secondary stress
        '\u02d0', # ː length mark
        '\u026a', # ɪ small capital i
        '\u028a', # ʊ upsilon
        '\u0259', # ə schwa
        '\u028c', # ʌ turned v
        '\u025a', # ɚ rhotic schwa
        '\u025c', # ɜ reversed open e
        '\u025d', # ɝ rhotic ɜ
        '\u00e6', # æ ash
        '\u0251', # ɑ script a
        '\u0252', # ɒ turned alpha
        '\u0254', # ɔ open o
        '\u025b', # ɛ open e
        '\u03b8', # θ theta
        '\u00f0', # ð eth
        '\u0283', # ʃ esh
        '\u0292', # ʒ ezh
        '\u014b', # ŋ eng
        '\u0261', # ɡ script g
        '\u0294', # ʔ glottal stop
    ]

    # Vietnamese full character set (lowercase and uppercase with tones)
    vietnamese_chars = list(
        'àáảãạăắằẳẵặâấầẩẫậ'
        'èéẻẽẹêếềểễệ'
        'ìíỉĩị'
        'òóỏõọôốồổỗộơớờởỡợ'
        'ùúủũụưứừửữự'
        'ỳýỷỹỵ'
        'đ'
        'ÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ'
        'ÈÉẺẼẸÊẾỀỂỄỆ'
        'ÌÍỈĨỊ'
        'ÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ'
        'ÙÚỦŨỤƯỨỪỬỮỰ'
        'ỲÝỶỸỴ'
        'Đ'
    )

    # Standard ASCII chars from 32 to 126
    ascii_chars = [chr(c) for c in range(32, 127)]
    all_chars = sorted(list(set(ascii_chars + ipa_chars + vietnamese_chars)), key=lambda c: ord(c))

    img = Image.new('RGBA', (tex_w, tex_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cur_x = 1
    cur_y = 1
    max_row_h = 0
    padding = 2

    char_entries = []

    for c in all_chars:
        cid = ord(c)
        if cid == 32: # space
            adv = int(round(font.getlength(' ')))
            char_entries.append((cid, 0, 0, 0, 0, 0, 0, adv))
            continue

        bbox = font.getbbox(c, anchor='ls') # (left, top, right, bottom)
        adv = int(round(font.getlength(c)))

        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]

        if w <= 0 or h <= 0:
            char_entries.append((cid, 0, 0, 0, 0, 0, 0, adv))
            continue

        if cur_x + w + padding >= tex_w:
            cur_x = 1
            cur_y += max_row_h + padding
            max_row_h = 0

        # Draw glyph in white
        draw.text((cur_x - bbox[0], cur_y - bbox[1]), c, font=font, fill=(255, 255, 255, 255), anchor='ls')

        xoffset = bbox[0]
        yoffset = base + bbox[1]

        char_entries.append((cid, cur_x, cur_y, w, h, xoffset, yoffset, adv))

        cur_x += w + padding
        if h > max_row_h:
            max_row_h = h

    png_name = f'{name}_0.png'
    png_path = os.path.join('resources/fonts', png_name)
    img.save(png_path, 'PNG')

    fnt_path = os.path.join('resources/fonts', f'{name}.fnt')
    with open(fnt_path, 'w', encoding='utf-8') as f:
        f.write(f'info face="Segoe UI" size={font_size} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1\n')
        f.write(f'common lineHeight={line_height} base={base} scaleW={tex_w} scaleH={tex_h} pages=1 packed=0\n')
        f.write(f'page id=0 file="{png_name}"\n')
        f.write(f'chars count={len(char_entries)}\n')
        for cid, x, y, w, h, xoff, yoff, adv in char_entries:
            f.write(f'char id={cid:<5} x={x:<4} y={y:<4} width={w:<3} height={h:<3} xoffset={xoff:<3} yoffset={yoff:<3} xadvance={adv:<3} page=0 chnl=15\n')

    print(f'Generated {font_size}px font ({len(char_entries)} chars, lineHeight={line_height}) in {fnt_path} and {png_path}')


def generate_badge_digit_font():
    """Generates a tight 9px-tall semibold digit font for battery/notification pills with slim strokes and zero vertical drift."""
    os.makedirs('resources/fonts', exist_ok=True)
    font = ImageFont.truetype('C:/Windows/Fonts/seguisb.ttf', 13)
    chars = list('0123456789+')
    tex_w, tex_h = 128, 32
    img = Image.new('RGBA', (tex_w, tex_h), (0, 0, 0, 0))

    cur_x = 1
    cur_y = 2
    entries = []
    target_h = 9

    for c in chars:
        tmp = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(tmp)
        d.text((4, 4), c, font=font, fill=(255, 255, 255, 255))
        # Trim faint AA halo (< 95 alpha) so strokes don't bloat on Garmin 64-color MIP
        tpx = tmp.load()
        for yy in range(24):
            for xx in range(24):
                r, g, b, a = tpx[xx, yy]
                if a < 95:
                    tpx[xx, yy] = (0, 0, 0, 0)
                elif a < 180:
                    tpx[xx, yy] = (255, 255, 255, 170)
                else:
                    tpx[xx, yy] = (255, 255, 255, 255)

        rows = [y for y in range(24) if any(tpx[x, y][3] > 0 for x in range(24))]
        cols = [x for x in range(24) if any(tpx[x, y][3] > 0 for y in range(24))]
        r0, r1 = min(rows), max(rows)
        c0, c1 = min(cols), max(cols)
        glyph = tmp.crop((c0, r0, c1 + 1, r1 + 1))
        gw, gh = glyph.size
        yoff = max(0, (target_h - gh) // 2)
        img.paste(glyph, (cur_x, cur_y))
        adv = gw + 1
        entries.append((ord(c), cur_x, cur_y, gw, gh, 0, yoff, adv))
        cur_x += gw + 2

    png_path = 'resources/fonts/badge_0.png'
    fnt_path = 'resources/fonts/badge.fnt'
    img.save(png_path, 'PNG')
    with open(fnt_path, 'w', encoding='utf-8') as f:
        f.write(f'info face="Segoe UI Semibold" size=13 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1\n')
        f.write(f'common lineHeight={target_h} base={target_h} scaleW={tex_w} scaleH={tex_h} pages=1 packed=0\n')
        f.write('page id=0 file="badge_0.png"\n')
        f.write(f'chars count={len(entries)}\n')
        for cid, x, y, w, h, xoff, yoff, adv in entries:
            f.write(f'char id={cid:<5} x={x:<4} y={y:<4} width={w:<3} height={h:<3} xoffset={xoff:<3} yoffset={yoff:<3} xadvance={adv:<3} page=0 chnl=15\n')
    print(f'Generated exact {target_h}px slim badge font in {fnt_path} and {png_path}')


if __name__ == '__main__':
    generate_bmfont('phonetic', 'C:/Windows/Fonts/segoeui.ttf', 17, 256, 384)
    generate_bmfont('meaning', 'C:/Windows/Fonts/segoeui.ttf', 14, 256, 300)
    generate_badge_digit_font()
