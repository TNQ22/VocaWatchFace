import ctypes
from ctypes import wintypes
import os
import sys
from PIL import Image

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

# 1. Switch to default desktop where user/interactive processes live
hDesk = user32.OpenDesktopW("default", 0, False, 0x10000000)
if hDesk:
    user32.SetThreadDesktop(hDesk)

# 2. Find CIQ Simulator window
found_hwnd = None
found_title = ""

def enum_proc(hwnd, lParam):
    global found_hwnd, found_title
    if user32.IsWindowVisible(hwnd):
        length = user32.GetWindowTextLengthW(hwnd)
        if length > 0:
            buff = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buff, length + 1)
            title = buff.value
            if "ciq simulator" in title.lower() or "forerunner" in title.lower():
                found_hwnd = hwnd
                found_title = title
                return False
    return True

EnumWindowsProc = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
user32.EnumWindows(EnumWindowsProc(enum_proc), 0)

if not found_hwnd:
    print("Simulator window not found!")
    sys.exit(1)

print(f"Found window: HWND={found_hwnd}, Title='{found_title}'")

# 3. Get window rect and client offset
rect = wintypes.RECT()
user32.GetWindowRect(found_hwnd, ctypes.byref(rect))
w = rect.right - rect.left
h = rect.bottom - rect.top

pt = wintypes.POINT(0, 0)
user32.ClientToScreen(found_hwnd, ctypes.byref(pt))
dx = pt.x - rect.left
dy = pt.y - rect.top
print(f"Window size: {w}x{h}, Client offset: dx={dx}, dy={dy}")

# 4. PrintWindow
hdc = user32.GetWindowDC(found_hwnd)
hMemDC = gdi32.CreateCompatibleDC(hdc)
hBmp = gdi32.CreateCompatibleBitmap(hdc, w, h)
gdi32.SelectObject(hMemDC, hBmp)

res = user32.PrintWindow(found_hwnd, hMemDC, 2)
if not res:
    res = user32.PrintWindow(found_hwnd, hMemDC, 0)
print(f"PrintWindow result: {res}")

# 5. Extract DIB bits
class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ('biSize', wintypes.DWORD),
        ('biWidth', wintypes.LONG),
        ('biHeight', wintypes.LONG),
        ('biPlanes', wintypes.WORD),
        ('biBitCount', wintypes.WORD),
        ('biCompression', wintypes.DWORD),
        ('biSizeImage', wintypes.DWORD),
        ('biXPelsPerMeter', wintypes.LONG),
        ('biYPelsPerMeter', wintypes.LONG),
        ('biClrUsed', wintypes.DWORD),
        ('biClrImportant', wintypes.DWORD),
    ]

bmi = BITMAPINFOHEADER()
bmi.biSize = ctypes.sizeof(BITMAPINFOHEADER)
bmi.biWidth = w
bmi.biHeight = -h  # top-down
bmi.biPlanes = 1
bmi.biBitCount = 32
bmi.biCompression = 0

buf = ctypes.create_string_buffer(w * h * 4)
gdi32.GetDIBits(hMemDC, hBmp, 0, h, buf, ctypes.byref(bmi), 0)

# Cleanup GDI
gdi32.DeleteObject(hBmp)
gdi32.DeleteDC(hMemDC)
user32.ReleaseDC(found_hwnd, hdc)

# Convert to PIL Image
img = Image.frombuffer('RGBA', (w, h), buf, 'raw', 'BGRA', 0, 1).convert('RGB')

# Output paths
art_dir = r"C:\Users\TNQ\.t3\userdata\providers\antigravity\ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32\antigravity-acp\brain\ece86122-7d36-45ea-b390-ff309f16de4a"

# Calculate display rect (fr245m: client x=77, y=189, width=240, height=240)
sx = dx + 77
sy = dy + 189

screen = img.crop((sx, sy, sx + 240, sy + 240))
watch = img.crop((sx - 40, sy - 50, sx + 240 + 40, sy + 240 + 50))

screen_path = os.path.join(art_dir, "simulator_fr245_screen.png")
watch_path = os.path.join(art_dir, "simulator_fr245_watch.png")

screen.save(screen_path)
watch.save(watch_path)
print(f"Saved screen crop (240x240) to {screen_path}")
print(f"Saved watch crop to {watch_path}")
