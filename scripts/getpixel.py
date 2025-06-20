import pyautogui
from PIL import ImageGrab
import sys

def get_pixel_color_at_cursor():
    x, y = pyautogui.position()
    screenshot = ImageGrab.grab()
    pixel_color = screenshot.getpixel((x, y))
    return (x, y, pixel_color)

def main():
    if not (len(sys.argv) > 1 and sys.argv[1] == "True"):
        print("Натисніть Enter для зчитування пікселя...")
        while True:
            input()  # Чекаємо натискання Enter
            x, y, color = get_pixel_color_at_cursor()
            print(f"(({x}, {y}), {color})")
    else:
        x, y, color = get_pixel_color_at_cursor()
        print(f"(({x}, {y}), {color})")

if __name__ == "__main__":
    main()
