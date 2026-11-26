import os
from PIL import Image, ImageFont, ImageDraw


def generate_bmfont(name: str, font_path: str, font_size: int, tex_w: int = 256, tex_h: int = 384, cutoff_override: int = 95, two_step: bool = True):
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

        # Draw glyph in white onto temporary small canvas, clean faint halo so MIP doesn't bloat strokes
        gw_pad = w + 4
        gh_pad = h + 4
        gtmp = Image.new('RGBA', (gw_pad, gh_pad), (0, 0, 0, 0))
        gd = ImageDraw.Draw(gtmp)
        gd.text((2 - bbox[0], 2 - bbox[1]), c, font=font, fill=(255, 255, 255, 255), anchor='ls')

        gpx = gtmp.load()
        max_a = max(gpx[xx, yy][3] for yy in range(gh_pad) for xx in range(gw_pad))
        # Preserve small punctuation/dots (like '.', ',') while trimming bloated AA halos
        cutoff = cutoff_override if max_a >= 165 else max(45, max_a // 2)
        for yy in range(gh_pad):
            for xx in range(gw_pad):
                a = gpx[xx, yy][3]
                if a < cutoff:
                    gpx[xx, yy] = (0, 0, 0, 0)
                else:
                    # Boost dim dot peaks slightly so tiny glyphs don't vanish on MIP
                    na = min(255, int(round(a * 255.0 / max_a))) if max_a < 180 else a
                    if two_step and na < 185:
                        gpx[xx, yy] = (255, 255, 255, 170)
                    else:
                        gpx[xx, yy] = (255, 255, 255, 255)

        img.paste(gtmp.crop((2, 2, 2 + w, 2 + h)), (cur_x, cur_y))

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
    """Generates a tight 9px-tall pixel-symmetric bold digit font (uniform 2px strokes, pure binary 0/255)."""
    os.makedirs('resources/fonts', exist_ok=True)
    glyphs = {
        '0': [
            '.####.',
            '######',
            '##..##',
            '##..##',
            '##..##',
            '##..##',
            '##..##',
            '######',
            '.####.',
        ],
        '1': [
            '..##',
            '.###',
            '####',
            '..##',
            '..##',
            '..##',
            '..##',
            '..##',
            '..##',
        ],
        '2': [
            '.####.',
            '######',
            '....##',
            '...###',
            '..###.',
            '.###..',
            '##....',
            '######',
            '######',
        ],
        '3': [
            '.####.',
            '######',
            '....##',
            '..###.',
            '..###.',
            '....##',
            '....##',
            '######',
            '.####.',
        ],
        '4': [
            '...###',
            '..####',
            '.##.##',
            '##..##',
            '##..##',
            '######',
            '######',
            '....##',
            '....##',
        ],
        '5': [
            '######',
            '######',
            '##....',
            '#####.',
            '.#####',
            '....##',
            '....##',
            '######',
            '.####.',
        ],
        '6': [
            '.####.',
            '#####.',
            '##....',
            '#####.',
            '######',
            '##..##',
            '##..##',
            '######',
            '.####.',
        ],
        '7': [
            '######',
            '######',
            '....##',
            '...##.',
            '...##.',
            '..##..',
            '..##..',
            '..##..',
            '..##..',
        ],
        '8': [
            '.####.',
            '######',
            '##..##',
            '.####.',
            '.####.',
            '##..##',
            '##..##',
            '######',
            '.####.',
        ],
        '9': [
            '.####.',
            '######',
            '##..##',
            '##..##',
            '######',
            '.#####',
            '....##',
            '.#####',
            '.####.',
        ],
        '+': [
            '...#...',
            '...#...',
            '...#...',
            '#######',
            '...#...',
            '...#...',
            '...#...',
        ],
    }

    tex_w, tex_h = 128, 32
    img = Image.new('RGBA', (tex_w, tex_h), (0, 0, 0, 0))
    px = img.load()

    cur_x = 1
    cur_y = 2
    entries = []
    target_h = 9

    for c, rows in glyphs.items():
        gw = len(rows[0])
        gh = len(rows)
        for yy, row in enumerate(rows):
            for xx, ch in enumerate(row):
                if ch == '#':
                    px[cur_x + xx, cur_y + yy] = (255, 255, 255, 255)
        yoff = max(0, (target_h - gh) // 2)
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


def generate_date_font():
    """Generates a tight 14px-tall pixel-symmetric semibold font (uniform 2px strokes) for Date and Steps | HR rows."""
    os.makedirs('resources/fonts', exist_ok=True)
    glyphs = {
        '0': (0, 0, 10, [
            '..+###+..',
            '.#######.',
            '+##...##+',
            '##.....##',
            '##.....##',
            '##.....##',
            '##.....##',
            '##.....##',
            '##.....##',
            '##.....##',
            '+##...##+',
            '.#######.',
            '..+###+..',
        ]),
        '1': (0, 0, 6, [
            '...##',
            '..###',
            '.####',
            '##.##',
            '...##',
            '...##',
            '...##',
            '...##',
            '...##',
            '...##',
            '...##',
            '...##',
            '...##',
        ]),
        '2': (0, 0, 10, [
            '.+####+..',
            '########.',
            '##+...##+',
            '......+##',
            '......##.',
            '.....+##.',
            '....###..',
            '...###...',
            '..###+...',
            '.+##+....',
            '.##......',
            '########.',
            '########.',
        ]),
        '3': (0, 0, 10, [
            '.+####+..',
            '.#######.',
            '+##...##+',
            '......+##',
            '.....+##.',
            '..+####..',
            '..+####+.',
            '.....+##+',
            '......+##',
            '......+##',
            '+##...##+',
            '.#######.',
            '.+####+..',
        ]),
        '4': (0, 0, 10, [
            '.....###.',
            '....####.',
            '...#####.',
            '...##.##.',
            '..##..##.',
            '.##+..##.',
            '.##...##.',
            '##....##.',
            '#########',
            '#########',
            '......##.',
            '......##.',
            '......##.',
        ]),
        '5': (0, 0, 10, [
            '.#######.',
            '.#######.',
            '.##......',
            '.##......',
            '.######..',
            '.######+.',
            '.....+##.',
            '......##.',
            '......##.',
            '......##.',
            '.##...##.',
            '.#######.',
            '..+###+..',
        ]),
        '6': (0, 0, 10, [
            '...+###+.',
            '..######.',
            '.+##.....',
            '.##+.....',
            '+##+###..',
            '.#######.',
            '##.....##',
            '##.....##',
            '##.....##',
            '##.....##',
            '+##...##+',
            '.#######.',
            '..+###+..',
        ]),
        '7': (0, 0, 9, [
            '########',
            '########',
            '......##',
            '.....+##',
            '.....##.',
            '....##+.',
            '....##..',
            '...##+..',
            '...##...',
            '..##+...',
            '..##....',
            '..##....',
            '..##....',
        ]),
        '8': (0, 0, 10, [
            '..+###+..',
            '.#######.',
            '+##...##+',
            '##.....##',
            '+##...##+',
            '..#####..',
            '..#####..',
            '+##...##+',
            '##.....##',
            '##.....##',
            '+##...##+',
            '.#######.',
            '..+###+..',
        ]),
        '9': (0, 0, 10, [
            '..+###+..',
            '.#######.',
            '+##...##+',
            '##.....##',
            '##.....##',
            '##.....##',
            '+##...##+',
            '.#######.',
            '..###+##+',
            '.....+##.',
            '.....##+.',
            '.######..',
            '.+###+...',
        ]),
        '/': (0, 0, 8, [
            '.....##',
            '....+##',
            '....##.',
            '....##.',
            '...+##.',
            '...##..',
            '...##..',
            '..+##..',
            '..##...',
            '..##...',
            '.+##...',
            '.##....',
            '.##....',
            '+##....',
            '##.....',
        ]),
        'T': (0, 0, 9, [
            '########',
            '########',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
            '...##...',
        ]),
        'C': (0, 0, 10, [
            '..+####+.',
            '.########',
            '+##...+##',
            '##+......',
            '##.......',
            '##.......',
            '##.......',
            '##.......',
            '##.......',
            '##+......',
            '+##...+##',
            '.########',
            '..+####+.',
        ]),
        'N': (0, 0, 10, [
            '##.....##',
            '###....##',
            '####...##',
            '####+..##',
            '##.##..##',
            '##+##+.##',
            '##.+##.##',
            '##..##+##',
            '##..+####',
            '##...####',
            '##....###',
            '##.....##',
            '##.....##',
        ]),
        '-': (1, 6, 7, [
            '#####',
            '#####',
        ]),
        '|': (0, 0, 3, [
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
            '##',
        ]),
    }

    tex_w, tex_h = 256, 32
    img = Image.new('RGBA', (tex_w, tex_h), (0, 0, 0, 0))
    px = img.load()

    cur_x = 1
    cur_y = 2
    entries = [(32, 0, 0, 0, 0, 0, 0, 5)]
    target_h = 14

    for c, (xoff, yoff, adv, rows) in glyphs.items():
        gw = len(rows[0])
        gh = len(rows)
        for yy, row in enumerate(rows):
            for xx, ch in enumerate(row):
                if ch == '#':
                    px[cur_x + xx, cur_y + yy] = (255, 255, 255, 255)
                elif ch == '+':
                    px[cur_x + xx, cur_y + yy] = (255, 255, 255, 170)
        entries.append((ord(c), cur_x, cur_y, gw, gh, xoff, yoff, adv))
        cur_x += gw + 2

    png_path = 'resources/fonts/date_0.png'
    fnt_path = 'resources/fonts/date.fnt'
    img.save(png_path, 'PNG')
    with open(fnt_path, 'w', encoding='utf-8') as f:
        f.write(f'info face="Segoe UI Semibold" size=19 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1\n')
        f.write(f'common lineHeight={target_h} base={target_h} scaleW={tex_w} scaleH={tex_h} pages=1 packed=0\n')
        f.write('page id=0 file="date_0.png"\n')
        f.write(f'chars count={len(entries)}\n')
        for cid, x, y, w, h, xoff, yoff, adv in entries:
            f.write(f'char id={cid:<5} x={x:<4} y={y:<4} width={w:<3} height={h:<3} xoffset={xoff:<3} yoffset={yoff:<3} xadvance={adv:<3} page=0 chnl=15\n')
    print(f'Generated exact {target_h}px date font in {fnt_path} and {png_path}')


if __name__ == '__main__':
    generate_bmfont('phonetic', 'C:/Windows/Fonts/segoeuil.ttf', 18, 256, 384, cutoff_override=95, two_step=False)
    generate_bmfont('meaning', 'C:/Windows/Fonts/segoeuil.ttf', 16, 256, 340, cutoff_override=95, two_step=False)
    generate_badge_digit_font()
    generate_date_font()
