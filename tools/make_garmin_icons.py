import os
from PIL import Image

def generate_icons():
    os.makedirs('resources/drawables', exist_ok=True)
    
    # 1. ALARM (14x14) - Original 7492450 design
    alarm = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    alarm_map = [
        '..............',
        '..##......##..',
        '..##.####.##..',
        '...########...',
        '...##.#..##...',
        '..##..#...##..',
        '..##..###.##..',
        '..##......##..',
        '..##......##..',
        '...##....##...',
        '...########...',
        '...#.####.#...',
        '..#........#..',
        '..............'
    ]
    for y in range(14):
        for x in range(14):
            if alarm_map[y][x] == '#':
                alarm.putpixel((x, y), (255, 255, 255, 255))
    alarm.save('resources/drawables/icon_alarm.png')
    print('Saved icon_alarm.png (14x14)')

    # 2. PHONE / BLUETOOTH (14x14) - Original 7492450 design
    phone = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    phone_map = [
        '..............',
        '..###....#....',
        '..###..#.##...',
        '.####...##.#..',
        '.##......##...',
        '.##......#....',
        '.##......#....',
        '.##......##...',
        '.####...##.#..',
        '..###..#.##...',
        '..###....#....',
        '..............',
        '..............',
        '..............'
    ]
    for y in range(14):
        for x in range(14):
            if phone_map[y][x] == '#':
                phone.putpixel((x, y), (255, 255, 255, 255))
    phone.save('resources/drawables/icon_phone_bt.png')
    print('Saved icon_phone_bt.png (14x14)')

    # 3. MOON (14x14) - Original 7492450 design
    moon = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    moon_map = [
        '..............',
        '.....#........',
        '...###........',
        '..###.........',
        '..###.........',
        '.####.........',
        '.#####........',
        '.#####........',
        '..#####.......',
        '..#########...',
        '...#######....',
        '.....###......',
        '..............',
        '..............'
    ]
    for y in range(14):
        for x in range(14):
            if moon_map[y][x] == '#':
                moon.putpixel((x, y), (255, 255, 255, 255))
    moon.save('resources/drawables/icon_moon.png')
    print('Saved icon_moon.png (14x14)')

    # 4. HEADPHONE (14x14) - Symmetrical 2px smooth arch, no missing pixels
    headphone = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    hp_map = [
        '....######....',
        '..##########..',
        '.###......###.',
        '.##........##.',
        '.##........##.',
        '###........###',
        '###........###',
        '###........###',
        '###........###',
        '###........###',
        '###........###',
        '.##........##.',
        '..............',
        '..............'
    ]
    for y in range(14):
        for x in range(14):
            if hp_map[y][x] == '#':
                headphone.putpixel((x, y), (255, 255, 255, 255))
    headphone.save('resources/drawables/icon_headphone.png')
    print('Saved icon_headphone.png (14x14)')

    # 5. FOOTPRINTS (14x14) - Two walking footprints with rounded non-blunt toes
    footprints = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    ft_map = [
        '..##..........',
        '.####.........',
        '.####.........',
        '.####...##....',
        '..##...####...',
        '..##...####...',
        '..##...####...',
        '........##....',
        '........##....',
        '........##....',
        '..............',
        '..............',
        '..............',
        '..............'
    ]
    green = (0, 230, 118, 255)
    for y in range(14):
        for x in range(14):
            if ft_map[y][x] == '#':
                footprints.putpixel((x, y), green)
    footprints.save('resources/drawables/icon_footprints.png')
    print('Saved icon_footprints.png (14x14)')

if __name__ == '__main__':
    generate_icons()
