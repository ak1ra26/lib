#!/bin/bash -i
init_i # initialize settings for interactive scripts

config_file="$Dir_config/dv.cfg"
dv_last="$Dir_cache/dv_last"

echo "$@" > "$dv_last"
sed -i 's/https/ https/g;s/ /\n/g' "$dv_last"
sed -i '/^$/d' "$dv_last"
sed -i -r 's/&pkey=.+//' "$dv_last"
arrLinks=($(cat "$dv_last"))
count=1

for i in ${arrLinks[@]}
do
    case $i in
        *"w.youtube.com"*)
            dvpath="Videos/Youtube"
            log_file="dv_youtube"
            ;;
        *)
            if [[ -f "$config_file" ]]; then
                source "$config_file"
            else
                error "Config file not found: $config_file"
                dvpath="Videos/Other"
                log_file="dv_other"
            fi
            ;;
    esac
    [ ! -d "$Dir_Data/Media/$dvpath" ] && mkdir -p "$Dir_Data/Media/$dvpath"
    OK "Downloading: $count from ${#arrLinks[@]}"
    notify-send -a "DV" "Downloading" "$count from ${#arrLinks[@]}"
    yt-dlp -P "$Dir_Data/Media/$dvpath" --cookies-from-browser firefox --mark-watched --download-archive "$Dir_cache/$log_file" -f 'bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b' --embed-thumbnail --sub-langs en,uk --embed-subs --embed-metadata --no-progress $i -o '%(title)s [%(id)s].%(ext)s' --no-warnings --no-simulate
    count=$((count + 1))
done
OK "Finished!"
notify-send -a "DV" Finished\! "${#arrLinks[@]} items done"
