#!/bin/bash -i
init_i # initialize settings for interactive scripts
file=$Dir_cache/iqos

if [ "$1" == "-s" ]; then
    # Створюємо мітку часу та записуємо її до файлу
    timestamp=$(date +"%s")
    echo "$timestamp" >> $file
    echo "Створено мітку часу: $timestamp"
elif [ ! -s $file ]; then
    echo -e ${c_red}"Файл з мітками порожній, або не існує."${NC}
elif [ "$1" == "-c" ]; then
    > $file
    echo "Усі мітки видалено."
else
    current_time=$(date +"%s")

    echo "Часові інтервали для останніх трьох міток часу від куріння IQOS:"
    tail -n 3 $file | while read line; do
        # Обчислюємо інтервал у годинах і хвилинах:
        interval=$((current_time - line))
        hours=$((interval / 3600))
        minutes=$(( (interval % 3600) / 60 ))

        if [ $hours -gt 0 ]; then
            if [ $minutes -gt 0 ]; then
                echo "$hours год. $minutes хв."
            else
                echo "$hours год."
            fi
        else
            echo "$minutes хв."
        fi
    done
fi
