#!/bin/bash -i
init_i # initialize settings for interactive scripts

# Path to the tasks file
TASK_FILE="$Dir_cache/tasks"
OP_FILE="$Dir_cache/tasks_op"
VERBOSE=false
mode=task
editor=vim
FILE="$TASK_FILE"
forced=""

# Usage information function
function usage {
    verbose "Displaying help"
    echo "Usage: t [-h|--help] [-v|--verbose] [-o|--op|--opt]"
    echo "Options:"
    echo "  -h, --help              Display this usage information"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -o, --op, --opt         Enable OPT mode - tasks that take up only 1% of my time."
    echo ""
    echo "Hints:"
    echo -e "Displayed in ${c_blue}blue${NC} - indicating important tasks."
    echo -e "Displayed in ${c_gray}gray${NC} - indicating postponed tasks."
    echo -e "Displayed in ${c_pink}pink${NC} - indicating tasks that can be done while working."
    echo -e "Displayed in ${c_green}green${NC} - indicating tasks to do on your days off."
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0;;
        -v|--verbose) VERBOSE=true;;
        -o|--op|--opt) mode=op; FILE="$OP_FILE"; verbose "OP mode is ON";;
        *) error "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Function to clear the screen
function clear_screen {
    if [ "$VERBOSE" = true ]; then
        verbose "Clearing screen is disabled in verbose mode."
    else
        clear
    fi
}

# check if the task file exists, create it if it doesn't
verbose "Checking if tasks file exists"
if [ ! -f "$TASK_FILE" ]; then
    confirm "Task file is not found. Do you want to create it?" || exit 1
    touch "$TASK_FILE"
    verbose "Task file created"
else
    OK
fi

# check if the OPT file exists, create it if it doesn't
verbose "Checking if OPT file exists"
if [ ! -f "$OP_FILE" ]; then
    confirm "OPT file is not found. Do you want to create it?" || exit 1
    touch "$OP_FILE"
    verbose "OPT file created"
else
    OK
fi

verbose "Checking if $editor is installed"
if ! command -v $editor &>/dev/null; then
    error "$editor не встановлено"
    confirm "$editor is not found. Would you like to install it?" || exit 1
    if [ -x "$(command -v apt)" ]; then
        sudo apt update
        sudo apt install vim -y
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Sy vim --noconfirm
    else
    error "Не підтримується дистрибутив Linux. Встановіть $editor вручну"
    exit 1
    fi
    else
        OK
fi

function add_space {
    if [ "$1" -le 9 ] && [ "$(wc -l < "$TASK_SPACE")" -ge 10 ]; then echo "$1.  "; else echo "$1. "; fi
}

function display_tasks {
    verbose "Displaying OP tasks"
    if [ -s "$OP_FILE" ]; then # Checks if the OPT file is not empty
        [[ "$mode" == "op" ]] && echo -e "→ OPT:$forced" || echo "OPT:"
        lineno=1 # Initializes the line counter
        TASK_SPACE=$OP_FILE
        while read -r line; do
            line_date=$(echo "$line" | sed 's/^\[\([^]]*\)\].*/\1/')
            line="${line#*]}" # Removes everything before the first "]"
            if [ "$(date +'%y%m%d')" = "$line_date" ]; then
            mark="${c_green}✔${NC} "
            else
            mark="${c_red}✘${NC} "
            fi
            if [ "$lineno" = "$1" ] && [[ "$mode" == "op" ]]; then
                echo -e "${c_red}$(add_space $lineno)$mark${c_red}$line${NC}"
            else
                echo -e "$(add_space $lineno)$mark$line"
            fi
            ((lineno++))
        done < "$OP_FILE"
        echo;
    else
        error "No OP file"
    fi
    verbose "Displaying tasks"
    [[ "$mode" == "task" ]] && echo -e "→ Tasks:$forced" || echo "Tasks:"
    if [ -s "$TASK_FILE" ]; then # Checks if the task file is not empty
        lineno=1 # Initializes the line counter
        TASK_SPACE=$TASK_FILE
        while read -r line; do
            if [ "${line:0:1}" = "!" ]; then
                var_c="${c_blue}"
                line="${line:1}"
            elif [ "${line:0:2}" = "@w" ]; then
                var_c="${c_pink}"
                line="${line:2}"
            elif [ "${line:0:1}" = "-" ]; then
                var_c="${c_gray}"
                line="${line:1}"
            elif [ "${line:0:2}" = "@f" ]; then
                var_c="${c_green}"
                line="${line:2}"
            else
                var_c="${NC}"
            fi
            if [ "$lineno" = "$1" ] && [[ "$mode" == "task" ]]; then var_c="${c_red}"; fi
            echo -e "${var_c}$(add_space $lineno)$line${NC}"
            ((lineno++))
        done < "$TASK_FILE"
        echo;
    else
        echo "No tasks yet"
    fi
}

# Add a new task to the list
function add_task {
    verbose "Adding new task"
    # create a temporary file for entering the task
    tmp_file=$(mktemp)
    $editor "$tmp_file"

    if [[ -s "$tmp_file" ]]; then
        task=$(cat "$tmp_file" | sed '/^[[:space:]]*$/d') # remove empty lines
        if [ "$(cat "$tmp_file" | wc -l)" -gt 1 ]; then
            clear_screen
            error "The new task contains multiple lines:"
            cat "$tmp_file"
            error "New task not saved."
        elif [[ "$task" =~ [^[:space:]] ]]; then
            if [[ $mode == "op" ]]; then
                echo "[]$task" >> "$OP_FILE"
            else
                echo "$task" >> "$FILE"
            fi
            echo "[$(date +'%y%m-%d %H:%M')] added [${task}]" >> "$FILE.log"
            clear_screen
            display_tasks
            OK "Task added."
        else
            error "Task cannot be empty or contain only whitespace."
            return
        fi
    else
        display_tasks
        error "Task not added."
    fi
    verbose "Remove the temporary file"
    rm "$tmp_file" && [ ! -f "$tmp_file" ] && OK || error -v "File deletion failed"
}

# Edit an existing task
function edit_task {
    verbose "Editing a task"
    get_num "Enter the number of the task to edit"
    if [ "$num" = "q" ]; then clear_screen; display_tasks; return; fi
    if [ "$(wc -l < "$FILE")" -lt "$num" ]; then error "Invalid task number."; edit_task; return; fi

    # create a temporary file for editing the task
    tmp_file=$(mktemp)
    if [ "$mode" = "op" ]; then
    sed -n "${num}s/.*\]//p" "$FILE" > "$tmp_file"
    else
    sed -n "${num}p" "$FILE" > "$tmp_file"
    fi
    # open the temporary file in editor
    $editor "$tmp_file"

    # check if the task contains multiple lines
    if [ "$(cat "$tmp_file" | wc -l)" -gt 1 ]; then
        clear_screen
        error "The edited task contains multiple lines:"
        cat "$tmp_file"
        error "Changes not saved."
        verbose "Remove the temporary file"
        rm "$tmp_file" && [ ! -f "$tmp_file" ] && OK || error -v "File deletion failed"
    else
        # Check if the edited task is not empty or contain only whitespace characters
        edited_task=$(cat "$tmp_file")
        if [[ ! "$edited_task" =~ ^[[:space:]]*$ ]]; then
            echo "[$(date +'%y%m-%d %H:%M')] edited from [$(sed -n "${num}p" "$FILE")] to [${edited_task}]" >> "$FILE.log"
            if [ "$mode" = "op" ]; then
            sed -i "${num}s/].*/]$edited_task/" "$FILE"
            else
            # replace the task in the original file with the edited task from the temporary file
            awk -v num="$num" -v task="$edited_task" 'BEGIN { FS="\n"; OFS="\n" } { if (NR==num) { $0=task } print }' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
            fi
            OK
            clear_screen
            display_tasks
            OK "Task edited."
        else
            error "Task cannot be empty or contain only whitespace."
            verbose "Remove the temporary file"
            rm "$tmp_file" && [ ! -f "$tmp_file" ] && OK || error -v "File deletion failed"
            return
        fi
    fi

    verbose "Remove the temporary file"
    rm "$tmp_file" && [ ! -f "$tmp_file" ] && OK || error -v "File deletion failed"
}

# Remove a task from the list
function delete_task {
    verbose "Deleting a task"
    get_num "Enter the number of the task to delete"
    if [ "$num" = "q" ]; then return; fi
    if [ "$num" -gt "$(wc -l < "$FILE")" ]; then
        echo -e "${c_red}Invalid task number.${NC}"
        delete_task
        return
    fi
    clear_screen
    display_tasks "$num"
    confirm "Are you sure you want to delete ${c_red}this${NC} task?" || { clear_screen; display_tasks; return; }
    echo "[$(date +'%y%m-%d %H:%M')] deleted [$(sed -n "${num}p" "$FILE")]"  >> "$FILE.log"
    sed -i "${num}d" "$FILE"
    clear_screen
    display_tasks
    OK "Task deleted."
}

function mark_opt {
    verbose "Marking a task"
    get_num "Enter the number of the task to mark"
    if [ "$num" = "q" ]; then return; fi
    if [ "$num" -gt "$(wc -l < "$OP_FILE")" ]; then
    echo -e "${c_red}Invalid task number.${NC}"
    mark_opt
    return
    fi

     # Отримання потрібного рядка з файлу
    line=$(sed -n "${num}p" "$OP_FILE")

    # Заміна або додавання дати у рядок
    if [[ "$line" =~ ^\[[0-9]{6}\].* ]]; then
        line_date="${line:1:6}"
        if [ "$(date +'%y%m%d')" = "$line_date" ]; then
            line="[]${line#\[??????\]}"
        else
            line="[$(date +'%y%m%d')]${line#\[??????\]}"
        fi
    else
        line="[$(date +'%y%m%d')]${line#\[\]}"
    fi

    # Заміна рядка у файлі
    sed -i "${num}s/.*/$line/" "$OP_FILE"

    clear_screen
    display_tasks
    OK "Task marked."
}

function task_tag {
    verbose "Adding tag to a task"
    get_num "Enter the number of the task to tag"
    if [ "$num" = "q" ]; then return; fi
    if [ "$num" -gt "$(wc -l < "$TASK_FILE")" ]; then
        echo -e "${c_red}Invalid task number.${NC}"
        task_tag
        return
    fi
    clear_screen
    display_tasks "$num"
    printf "What tag do you want to add? (${c_red}c${NC}lear tag, ${c_red}i${c_blue}mportant${NC}, ${c_red}f${c_green}ree${NC}, ${c_red}w${c_pink}ork${NC}, ${c_red}p${c_gray}ostponed${NC}, ${c_red}q${NC}uit): "
    read choice
    clear_screen
    case $choice in
        c|"")
            tag="";;
        i|!)
            tag="!";;
        f)
            tag="@f";;
        w)
            tag="@w";;
        p|-)
            tag="-";;
        q)
            verbose "Exit"; display_tasks; return;;
        *)
            error "Invalid choice."; verbose "Exit"; display_tasks; return;;
    esac

    # Змінюємо рядок з тегами в файлі
    # sed -i "${num}s/^\([!-]\|@\([fw]\)\)\(.*\)$/\\1$tag\3/; t; ${num}!s/^/$tag/" "$TASK_FILE"
    sed -i "${num} { /^\([!-]\|@\([fw]\)\)/ s//${tag}/; t; s/^/${tag}/; }" "$TASK_FILE"
    clear_screen
    display_tasks
    OK "Tag added."
}

clear_screen;
display_tasks;

# Main loop
while true; do
    if [[ $mode == "task" ]]; then
    printf "What do you want to do? (${c_red}t${NC}ag, ${c_red}d${NC}isplay, ${c_red}a${NC}dd, ${c_red}e${NC}dit, ${c_red}r${NC}emove, ${c_red}m${NC}ode, ${c_red}h${NC}elp, ${c_red}q${NC}uit): "
    else
    printf "What do you want to do? (${c_red}v${NC} - mark as done, ${c_red}d${NC}isplay, ${c_red}a${NC}dd, ${c_red}e${NC}dit, ${c_red}r${NC}emove, ${c_red}m${NC}ode, ${c_red}h${NC}elp, ${c_red}q${NC}uit): "
    fi
    read choice
    clear_screen
    case $choice in
        t|е)
            [[ "$mode" == "op" ]] && { mode="task"; forced=" ${c_red}(forced)${NC}"; FILE="$TASK_FILE"; verbose "Forced into task mode"; }
            display_tasks
            task_tag;;
        d|в)
            display_tasks;;
        v|м)
            [[ ! "$mode" == "op" ]] && { mode="op"; forced=" ${c_red}(forced)${NC}"; FILE="$OP_FILE"; verbose "Forced into OTP mode"; }
            display_tasks; mark_opt;;
        a|ф)
            add_task;;
        h|р)
            usage; echo;;
        e|у)
            display_tasks
            edit_task;;
        r|к)
            display_tasks
            delete_task;;
        m|ь)
            [[ "$mode" == "task" ]] && { mode="op"; FILE="$OP_FILE"; forced=""; } || { mode="task"; FILE="$TASK_FILE"; forced=""; }
            OK "Mod changed to: $mode"
            clear_screen
            display_tasks;;
        q|й)
            verbose Exit; break;;
        *)
            error "Invalid choice."; verbose "Exit"; display_tasks;;
    esac
done
