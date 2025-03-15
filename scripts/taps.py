import time
import random
import threading
import curses
import logging
from pynput.mouse import Controller, Button

mouse = Controller()

# Діапазони координат для sFOMO
sFomoClick_areas = [
    ((27, 472), (357, 494)),
    ((323, 368), (358, 368)),
    ((54, 406), (330, 419)),
]

# Діапазони координат для fomo_hash
fomoHash_click_areas = [
    ((21, 805), (364, 822)),
    ((306, 892), (361, 902)),
    ((36, 1008), (358, 1025)),
]

# Діапазони координат для Hamster King
rvp_click_area = [
    ((628, 441), (778, 472)),
    ((612, 511), (794, 537)),
]

# Замок для синхронізації доступу до миші
lock = threading.Lock()
stop_event = threading.Event()
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

def random_point(area):
    (x1, y1), (x2, y2) = area
    return random.randint(x1, x2), random.randint(y1, y2)

def sFomo_clicks():
    while not stop_event.is_set():
        for area in sFomoClick_areas:
            x, y = random_point(area)
            with lock:
                mouse.position = (x, y)
                mouse.click(Button.left, 1)
            time.sleep(random.uniform(0.5, 2))

        wait_time = random.randint(2400, 4700)
        logging.info(f"[sFOMO] Чекаю {wait_time} секунд...")
        stop_event.wait(wait_time)

def fomoHash_clicks():
    while not stop_event.is_set():
        for area in fomoHash_click_areas:
            x, y = random_point(area)
            with lock:
                mouse.position = (x, y)
                mouse.click(Button.left, 1)
            time.sleep(random.uniform(0.5, 1.5))

        wait_time = random.randint(14430, 15120)
        logging.info(f"[#fomo_hash] Чекаю {wait_time} секунд...")
        stop_event.wait(wait_time)

def rvp_clicks():
    while not stop_event.is_set():
        for area in rvp_click_area:
            x, y = random_point(area)
            with lock:
                mouse.position = (x, y)
                mouse.click(Button.left, 1)
            time.sleep(random.uniform(16, 20))

        wait_time = random.randint(10800, 13200)
        logging.info(f"[Reverie Field Project] Чекаю {wait_time} секунд...")
        stop_event.wait(wait_time)

def menu(stdscr):
    curses.curs_set(0)
    options = [
        ("sFOMO", sFomo_clicks),
        ("#fomo_hash", fomoHash_clicks),
        ("Reverie Field Project", rvp_clicks)
    ]
    selected = [False] * len(options)
    idx = 0

    try:
        while True:
            stdscr.clear()
            stdscr.addstr("Виберіть потоки (SPACE - увімкнути/вимкнути, ENTER - старт):\n\n")
            for i, (name, _) in enumerate(options):
                marker = "[X]" if selected[i] else "[ ]"
                if i == idx:
                    stdscr.addstr(f"> {marker} {name}\n", curses.A_REVERSE)
                else:
                    stdscr.addstr(f"  {marker} {name}\n")
            stdscr.refresh()

            key = stdscr.getch()
            if key == curses.KEY_UP and idx > 0:
                idx -= 1
            elif key == curses.KEY_DOWN and idx < len(options) - 1:
                idx += 1
            elif key == 32:  # SPACE
                selected[idx] = not selected[idx]
            elif key == 10:  # ENTER
                break
            time.sleep(0.1)
    except KeyboardInterrupt:
        return []

    return [options[i][1] for i in range(len(options)) if selected[i]]


selected_functions = curses.wrapper(menu)

enabled_threads = [threading.Thread(target=func, daemon=True) for func in selected_functions]
for thread in enabled_threads:
    thread.start()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    stop_event.set()
    logging.info("Зупинка потоків...")
    for thread in enabled_threads:
        thread.join()
    logging.info("Всі потоки зупинені.")
