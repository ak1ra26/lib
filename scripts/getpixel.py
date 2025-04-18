import pyautogui
from PIL import ImageGrab
import time

def get_pixel_color_at_cursor():
    # Отримуємо поточні координати курсора
    x, y = pyautogui.position()
    
    # Робимо знімок екрана
    screenshot = ImageGrab.grab()
    
    # Отримуємо колір пікселя під курсором
    pixel_color = screenshot.getpixel((x, y))
    
    return (x, y, pixel_color)

def main():
    print("Натискайте Enter, щоб отримати піксель під курсором.")
    while True:
        input()  # Чекаємо натискання Enter
        x, y, color = get_pixel_color_at_cursor()
        # print(f"Координати: ({x}, {y})\nКолір пікселя: {color}")
        print(f"(({x}, {y}), {color})")

if __name__ == "__main__":
    main()
