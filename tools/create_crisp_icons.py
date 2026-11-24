import os
from PIL import Image, ImageDraw

def create_crisp_icons():
    os.makedirs('resources/drawables', exist_ok=True)
    
    # 1. Báo thức (Alarm) - 18x18px, nét 2px đậm rõ trên màn hình MIP
    img_alarm = Image.new('RGBA', (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_alarm)
    # Thân đồng hồ tròn
    d.ellipse([2, 3, 15, 16], outline=(255, 255, 255, 255), width=2)
    # Kim giờ và kim phút
    d.line([8, 9, 8, 6], fill=(255, 255, 255, 255), width=2)
    d.line([8, 9, 12, 9], fill=(255, 255, 255, 255), width=2)
    # Chuông 2 bên đỉnh
    d.line([2, 1, 5, 3], fill=(255, 255, 255, 255), width=2)
    d.line([15, 1, 12, 3], fill=(255, 255, 255, 255), width=2)
    # Chân đế
    d.line([3, 16, 2, 17], fill=(255, 255, 255, 255), width=2)
    d.line([14, 16, 15, 17], fill=(255, 255, 255, 255), width=2)
    img_alarm.save('resources/drawables/icon_alarm.png')

    # 2. Mặt trăng DND (Moon) - 18x18px, dày dặn mập mạp không bị mất nét
    img_moon = Image.new('RGBA', (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_moon)
    # Vẽ mặt trăng trắng bán kính 7px
    d.ellipse([1, 1, 16, 16], fill=(255, 255, 255, 255))
    # Khoét lõm bằng hình elip lệch phải
    d.ellipse([6, -1, 20, 16], fill=(0, 0, 0, 0))
    img_moon.save('resources/drawables/icon_moon.png')

    # 3. Tai nghe Bluetooth (Headphone) - 18x18px, quai over-ear dày 2px + 2 củ tai nghe đặc
    img_hp = Image.new('RGBA', (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_hp)
    # Quai đeo vòng cung đỉnh
    d.arc([1, 1, 16, 15], start=180, end=0, fill=(255, 255, 255, 255), width=2)
    # 2 củ tai nghe 2 bên
    d.rounded_rectangle([1, 8, 4, 16], radius=1, fill=(255, 255, 255, 255))
    d.rounded_rectangle([13, 8, 16, 16], radius=1, fill=(255, 255, 255, 255))
    img_hp.save('resources/drawables/icon_headphone.png')

    # 4. Điện thoại + Bluetooth (Phone + BT) - 18x18px
    # Chuẩn theo ảnh IMG_0249 của Garmin: ống nghe bên trái + ký hiệu Bluetooth bên phải
    img_phone_bt = Image.new('RGBA', (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_phone_bt)
    # Ống nghe điện thoại góc trái (dày dặn)
    d.polygon([(1, 4), (4, 1), (6, 3), (4, 5), (6, 9), (9, 7), (11, 9), (8, 12), (5, 11), (2, 7)], fill=(255, 255, 255, 255))
    # Ký hiệu Bluetooth bên phải (nét 2px)
    d.line([13, 2, 13, 15], fill=(255, 255, 255, 255), width=2)
    d.line([13, 2, 17, 5], fill=(255, 255, 255, 255), width=2)
    d.line([17, 5, 13, 8], fill=(255, 255, 255, 255), width=2)
    d.line([13, 8, 17, 12], fill=(255, 255, 255, 255), width=2)
    d.line([17, 12, 13, 15], fill=(255, 255, 255, 255), width=2)
    img_phone_bt.save('resources/drawables/icon_phone_bt.png')

    # 5. Dấu chân bước đi (Footprints) - 16x16px, màu xanh lá thể thao đặc
    # 2 bàn chân sole trái phải rõ ràng
    img_foot = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_foot)
    c_green = (0, 230, 118, 255)
    # Bàn chân trái (sau)
    d.ellipse([1, 8, 6, 15], fill=c_green)
    d.ellipse([2, 5, 5, 7], fill=c_green)
    # Bàn chân phải (trước)
    d.ellipse([9, 5, 14, 12], fill=c_green)
    d.ellipse([10, 2, 13, 4], fill=c_green)
    img_foot.save('resources/drawables/icon_footprints.png')

    print("All 5 crisp 18x18 and 16x16 MIP icons generated successfully.")

if __name__ == '__main__':
    create_crisp_icons()
