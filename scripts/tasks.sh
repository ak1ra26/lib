#!/bin/bash -i
init_i # initialize settings for interactive scripts

# Path to the tasks file
TASK_FILE="$Dir_cache/tasks"
OP_FILE="$Dir_cache/tasks_op"
VERBOSE=false
mode=task
editor=vim

# Usage information function
function usage {
    echo "Usage: t [-h|--help] [-v|--verbose] [-o|--op] [-f|--file <task_file>]"
    echo "Options:"
    echo "  -h, --help              Display this usage information"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -o, --op                Enable OPT mode"
    echo "  -f, --file <task_file>  Path to the task file (default: $TASK_FILE)"
    echo ""
    echo "Hints:"
    echo -e "Task starting with \"!\" will be displayed in ${c_blue}blue${NC} - important task."
    echo -e "Task starting with \"-\" will be displayed in ${c_gray}gray${NC} - postponed task."
    echo -e "Task starting with \"@w\" will be displayed in ${c_pink}pink${NC} - task that can be done while working."
    echo -e "Task starting with \"@f\" will be displayed in ${c_green}green${NC} - task to do in your days off."
    echo -e "Task starting with \"1%\" will be added in OPT - tasks that only take up 1% of my time."
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help|-р) usage; exit 0;;
        -v|--verbose|-м) VERBOSE=true;;
        -o|--op|-щ|--щз) mode=op; verbose "OP mode is ON";;
        -f|--file|-а) TASK_FILE="$2"; shift ;;
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
    confirm "Task file not found. Do you want to create it?" || exit 1
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
    if [ -s "$OP_FILE" ]; then
        [[ "$mode" == "op" ]] && echo "→ OPT:" || echo "OPT:"
        lineno=1
        TASK_SPACE=$OP_FILE
        while read -r line; do
            line="${line:2}" # Removes the first characters from the line
            if [ "$lineno" = "$1" ]; then
                echo -e "${c_red}$(add_space $lineno)$line${NC}"
            else
                echo -e "$(add_space $lineno)$line"
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
        var_c=""
            if [ "$lineno" = "$1" ]; then
                var_c="${c_red}"
            elif [ "${line:0:1}" = "!" ]; then
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
            fi
        echo -e "${var_c}$(add_space $lineno)$line${NC}"
        ((lineno++)) # Increments the line counter by 1
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
        # get the task from the temporary file
        task=$(cat "$tmp_file" | sed '/^[[:space:]]*$/d') # remove empty lines
        # Check if the entered task contains at least one non-whitespace character
        # check if the task contains multiple lines
        if [ "$(cat "$tmp_file" | wc -l)" -gt 1 ]; then
            clear_screen
            error "The new task contains multiple lines:"
            cat "$tmp_file"
            error "New task not saved."
        elif [[ "$task" =~ [^[:space:]] ]]; then
            if [[ "$task" =~ ^1% ]]; then
                echo "$task" >> "$OP_FILE"
            else
                echo "$task" >> "$TASK_FILE"
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
    if [ "$(wc -l < "$TASK_FILE")" -lt "$num" ]; then error "Invalid task number."; edit_task; return; fi

    # create a temporary file for editing the task
    tmp_file=$(mktemp)
    sed -n "${num}p" "$TASK_FILE" > "$tmp_file"

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
            # replace the task in the original file with the edited task from the temporary file
            awk -v num="$num" -v task="$edited_task" 'BEGIN { FS="\n"; OFS="\n" } { if (NR==num) { $0=task } print }' "$TASK_FILE" > "$TASK_FILE.tmp" && mv "$TASK_FILE.tmp" "$TASK_FILE"
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
    if [ "$num" -gt "$(wc -l < "$TASK_FILE")" ]; then
        echo -e "${c_red}Invalid task number.${NC}"
        delete_task
        return
    fi
    clear_screen
    display_tasks "$num"
    confirm "Are you sure you want to delete ${c_red}this${NC} task?" || { clear_screen; display_tasks; return; }
    sed -i "${num}d" "$TASK_FILE"
    clear_screen
    display_tasks
    OK "Task deleted."
}

clear_screen;
display_tasks;

# Main loop
while true; do
    printf "What do you want to do? (${c_red}d${NC}isplay, ${c_red}a${NC}dd, ${c_red}e${NC}dit, ${c_red}r${NC}emove, ${c_red}m${NC}ode, ${c_red}h${NC}elp, ${c_red}q${NC}uit): "
    read choice
    clear_screen
    case $choice in
        d|в)
            display_tasks;;
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
            [[ "$mode" == "task" ]] && mode="op" || mode="task" && OK "Mod changed to: $mode"; clear_screen; display_tasks;;
        q|й)
            verbose Exit; break;;
        *)
            error "Invalid choice.";;
    esac
done
