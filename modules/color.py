"""
This module defines ANSI escape code color variables for text styling in the terminal.

Variables:
    NC (str): No color, resets text styling to default.
    red (str): Red text color.
    green (str): Green text color.
    orange (str): Orange text color.
    yellow (str): Yellow text color.
    blue (str): Blue text color.
    mag (str): Magenta text color.
    cyan (str): Cyan text color.
    pink (str): Pink text color with RGB values (255, 105, 180).
    gray (str): Gray text color.

Usage:
    To use these color variables in your script, import them from the module, e.g.:
    
    ```python
    from modules.color import red, blue, NC
    
    print(f"{red}This is red text.{NC}")
    print(f"{blue}This is blue text.{NC}")
    ```
"""

NC = '\033[0m'

red = '\033[0;31m'
green = '\033[0;32m'
orange = '\033[0;33m'
yellow = '\033[0;93m'
blue = '\033[0;34m'
mag = '\033[0;35m'
cyan = '\033[0;36m'
pink = '\033[38;2;255;105;180m'
gray = '\033[0;90m'

bred = '\033[0;41m'
bcyan = '\033[7;36;47m'

# colored text
yon = f'{NC}[{green}Y{NC}/{red}n{NC}]'
on = f"{green}ON{NC}"
off = f"{red}OFF{NC}"
usage_text = f"""Usage: t [-h|--help] [-v|--verbose] [-o|--opt]
Options:
    -h, --help              Display this usage information
    -v, --verbose           Enable verbose output
    -o, --opt               Enable OPT mode - tasks that take up only 1% of my time.

Hints:
Displayed in {blue}blue{NC} - indicating important tasks.
Displayed in {gray}gray{NC} - indicating postponed tasks.
Displayed in {pink}pink{NC} - indicating tasks that can be done while working.
Displayed in {green}green{NC} - indicating tasks to do on your days off.
Displayed in {yellow}yellow{NC} - indicating tasks that require money.

При виборі задачі -1 обирає останню задачу.
Щоб додати задачу треба в input ввести її, але не менше 5 символів.
Щоб помітити задачу як виконану просто введіть в input її номер:
    ex.: {blue}1, 3, 8-11{NC} - mark 1, 3, 8, 9, 10 and 11 as done

Other options in menus:
    '{blue}Empty input{NC}' - refresh tasks / back to previous menu
    '{blue}h{NC}' - print this usage
    '{blue}q{NC}', '{blue}exit{NC}' - quite program / back to previous menu / відмінити вибір
    '{blue}.{NC}' - show all tasks (active and done)\n"""