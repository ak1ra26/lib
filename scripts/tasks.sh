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
    echo "Usage: t [-h|--help] [-v|--verbose] [-o|--op|--opt]"
    echo "Options:"
    echo "  -h, --help              Display this usage information"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -o, --op, --opt         Enable OPT mode - tasks that only take up 1% of my time."
    echo ""
    echo "Hints:"
    echo -e "Task starting with \"!\" will be displayed in ${c_blue}blue${NC} - important task."
    echo -e "Task starting with \"-\" will be displayed in ${c_gray}gray${NC} - postponed task."
    echo -e "Task starting with \"@w\" will be displayed in ${c_pink}pink${NC} - task that can be done while working."
    echo -e "Task starting with \"@f\" will be displayed in ${c_green}green${NC} - task to do in your days off."
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
    confirm "Task file not found. Do you want to create it?" || exit 1
    touch "$TASK_FILE"
    verbose "Task file created"
else
    OK
fi

# check if the OPT file exists, create it if it doesn't
verbose "Checking if OPT file exists"
if [ ! -f "$OP_FILE" ]; then
    confirm "OPT file not found. Do you want to create it?" || exit 1
    touch "$OP_FILE"
    verbose "OPT file created"
else
    OK
fi

function add_space {
    if [ "$1" -le 9 ] && [ "$(wc -l < "$TASK_SPACE")" -ge 10 ]; then echo "$1.  "; else echo "$1. "; fi
}

# function checkbox {
#     # echo -e "Enable: \033[32m✓\033[0m"
# }

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
    [[ "$mode" == "task" ]] && echo "→ Tasks:" || echo "Tasks:"
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
            if [ "$lineno" = "$1" ] && [[ "$mode" == "task" ]]; then
                var_c="${c_red}"
            fi
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
            clear_screen
            display_tasks
            OK "Task added."
        else
            error "Task cannot be empty or contain only whitespace."
            return
        fi
    else
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
                if [ "$mode" = "op" ]; then
                sed -i "${num}s/].*/]$edited_task/" "$FILE" # test this!!!!!!!!
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

clear_screen;
display_tasks;

# Main loop
while true; do
    if [[ $mode == "task" ]]; then
    printf "What do you want to do? (${c_red}d${NC}isplay, ${c_red}a${NC}dd, ${c_red}e${NC}dit, ${c_red}r${NC}emove, ${c_red}m${NC}ode, ${c_red}h${NC}elp, ${c_red}q${NC}uit): "
    else
    printf "What do you want to do? (${c_red}v${NC} - mark as done, ${c_red}d${NC}isplay, ${c_red}a${NC}dd, ${c_red}e${NC}dit, ${c_red}r${NC}emove, ${c_red}m${NC}ode, ${c_red}h${NC}elp, ${c_red}q${NC}uit): "
    fi
    read choice
    clear_screen
    case $choice in
        d|в)
            display_tasks;;
        v|м)
            [[ ! "$mode" == "op" ]] && { mode="op"; forced=" ${c_red}(forced)${NC}"; verbose "Forced into OTP mode"; }
            display_tasks; mark_opt;;
        a|ф)
            add_task;;
        h|р)
            verbose "Displaying help"; usage; echo;;
        e|у)
            display_tasks
            edit_task;;
        r|к)
            display_tasks
            delete_task;;
        m|ь)
            [[ "$mode" == "task" ]] && { mode="op"; FILE="$OP_FILE"; } || { mode="task"; FILE="$TASK_FILE"; forced=""; }
            OK "Mod changed to: $mode"
            clear_screen
            display_tasks;;
        q|й)
            verbose Exit; break;;
        *)
            error "Invalid choice.";;
    esac
done
