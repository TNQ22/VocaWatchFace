import os
from PIL import Image

def generate_icons():
    os.makedirs('resources/drawables', exist_ok=True)
    
    # 1. ICON HEADPHONE (14x14, Pure White #FFFFFF)
    # Headband: 2px continuous smooth arch connecting earcups
    # Earcups: Solid 3x7px cushions on each side (x=1..3 and x=10..12)
    # Zero missing pixels, solid 100% white for MIP screen
    hp = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    hp_pts = [
        # Top headband arch
        (5,0), (6,0), (7,0), (8,0),
        (3,1), (4,1), (5,1), (6,1), (7,1), (8,1), (9,1), (10,1),
        (2,2), (3,2), (4,2),                   (9,2), (10,2), (11,2),
        (2,3), (3,3),                                 (10,3), (11,3),
        (1,4), (2,4), (3,4),                   (10,4), (11,4), (12,4),
    ]
    # Solid ear cushions on both sides
    for y in range(5, 11):
        for x in range(1, 4):
            hp_pts.append((x, y))
        for x in range(10, 13):
            hp_pts.append((x, y))
    # Soft rounded bottom of ear cushions
    hp_pts.extend([(2, 11), (3, 11), (10, 11), (11, 11)])
    
    for pt in hp_pts:
        hp.putpixel(pt, (255, 255, 255, 255))
    hp.save('resources/drawables/icon_headphone.png')
    print('Generated icon_headphone.png')

    # 2. ICON MOON (14x14, Pure White #FFFFFF)
    # Smooth, crisp crescent moon silhouette
    moon = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    moon_pts = [
        (8,1),(9,1),
        (6,2),(7,2),(8,2),(9,2),
        (5,3),(6,3),(7,3),(8,3),
        (4,4),(5,4),(6,4),
        (3,5),(4,5),(5,5),
        (3,6),(4,6),(5,6),
        (3,7),(4,7),(5,7),
        (4,8),(5,8),(6,8),
        (5,9),(6,9),(7,9),(8,9),
        (6,10),(7,10),(8,10),(9,10),
        (8,11),(9,11)
    ]
    for pt in moon_pts:
        moon.putpixel(pt, (255, 255, 255, 255))
    moon.save('resources/drawables/icon_moon.png')
    print('Generated icon_moon.png')

    # 3. ICON ALARM (14x14, Pure White #FFFFFF)
    # Traditional alarm clock: round body, top bells, hands inside, slanted feet
    alarm = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    alarm_pts = [
        # Twin top bells
        (2,1),(3,1),(1,2),(2,2),
        (10,1),(11,1),(11,2),(12,2),
        # Round circular case (outline)
        (5,3),(6,3),(7,3),(8,3),
        (3,4),(4,4),           (9,4),(10,4),
        (2,5),(3,5),           (10,5),(11,5),
        (2,6),(3,6),           (10,6),(11,6),
        (2,7),(3,7),           (10,7),(11,7),
        (3,8),(4,8),           (9,8),(10,8),
        (5,9),(6,9),(7,9),(8,9),
        # Clock hands inside showing 3 o'clock
        (6,5),(6,6),(7,6),(8,6),
        # Slanted feet
        (3,10),(2,11),
        (10,10),(11,11)
    ]
    for pt in alarm_pts:
        alarm.putpixel(pt, (255, 255, 255, 255))
    alarm.save('resources/drawables/icon_alarm.png')
    print('Generated icon_alarm.png')

    # 4. ICON PHONE / BLUETOOTH (14x14, Pure White #FFFFFF)
    # Phone body with bluetooth rune inside
    phone = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    phone_pts = []
    for y in range(0, 14):
        for x in range(3, 11):
            if y == 0 or y == 13:
                if 4 <= x <= 9: # rounded corner
                    phone_pts.append((x, y))
            elif y == 1 or y == 12:
                phone_pts.append((x, y))
            else:
                if x == 3 or x == 10:
                    phone_pts.append((x, y))
    # Speaker notch & home indicator
    phone_pts.extend([(6, 1), (7, 1), (6, 12), (7, 12)])
    # Bluetooth rune inside screen
    phone_pts.extend([
        (6,4),(7,4),
        (6,5),(8,5),
        (6,6),(7,6),
        (6,7),(8,7),
        (6,8),(7,8)
    ] )
    for pt in phone_pts:
        phone.putpixel(pt, (255, 255, 255, 255))
    phone.save('resources/drawables/icon_phone_bt.png')
    print('Generated icon_phone_bt.png')

    # 5. ICON FOOTPRINTS / STEPS (14x14, Sport Green #00E676)
    # Garmin stock shoe sole silhouette:
    # Beautifully rounded toe (x=3..8, y=0..3), inner arch indent, and rounded heel (y=8..12)
    # Never cut off or blunt!
    foot = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
    green = (0, 230, 118, 255)
    
    # Garmin FR245 stock steps icon silhouette (natural rounded sneaker sole):
    foot_pts = [
        # Curved toe tip (rounded, not blunt)
        (4,0),(5,0),(6,0),(7,0),
        (3,1),(4,1),(5,1),(6,1),(7,1),(8,1),
        (2,2),(3,2),(4,2),(5,2),(6,2),(7,2),(8,2),(9,2),
        (2,3),(3,3),(4,3),(5,3),(6,3),(7,3),(8,3),(9,3),
        (2,4),(3,4),(4,4),(5,4),(6,4),(7,4),(8,4),
        # Inner arch curvature
        (3,5),(4,5),(5,5),(6,5),(7,5),
        (3,6),(4,6),(5,6),(6,6),(7,6),
        (3,7),(4,7),(5,7),(6,7),(7,7),
        # Heel
        (2,8),(3,8),(4,8),(5,8),(6,8),(7,8),
        (2,9),(3,9),(4,9),(5,9),(6,9),(7,9),
        (3,10),(4,10),(5,10),(6,10),(7,10),
        (3,11),(4,11),(5,11),(6,11),
        (4,12),(5,12)
    ]
    for pt in foot_pts:
        foot.putpixel(pt, green)
    foot.save('resources/drawables/icon_footprints.png')
    print('Generated icon_footprints.png')

if __name__ == '__main__':
    generate_icons()
