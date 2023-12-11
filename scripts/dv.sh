#!/bin/bash -i
init_i # initialize settings for interactive scripts

config_file="$Dir_config/dv.cfg"
dv_last="$Dir_cache/dv_last"

function usage {
    echo "Usage: $0 [-option1 -option2...] URL or \"URL1 URL2 URL3...\" [-option1 -option2...]"
    echo "Options:"
    echo "  -h, --help              Display this usage information"
    echo "  -v                      Enable verbose output"
    echo "  -r                      Forces the script to download and rewrite existing video files."
    echo "  -s                      Adds subtitles to the video if they are available."
    echo "  -t                      Adds a native thumbnail to the video."
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r) dv_vars+=("--no-download-archive" "--force-overwrites" "--force-write-archive");;
        -s) dv_vars+=("--sub-langs" "en,uk" "--embed-subs");;
        -t) dv_vars+=("--embed-thumbnail");;
        -h|--help) usage;;
        -v) dv_vars+=("--verbose");;
        *) urls+=("$1");;
    esac
    shift
done

[[ "${#urls[@]}" -eq 0 ]] && { echo "Error: No URL provided."; usage; }
echo "${urls[@]}" | sed -e 's/https/ https/g; s/ /\n/g; /^$/d' | awk '!seen[$0]++' > "$dv_last"
# sed -i 's/&pkey=watchlater//g' "$dv_last"
sed -i 's/\(&pkey=\|&list=\).*//g' "$dv_last"
arrLinks=($(cat "$dv_last"))
count=1
for i in "${arrLinks[@]}"; do
    if [[ $i == *"w.youtube.com"* ]]; then
        dvpath="Videos/Youtube"
        log_file="dv_youtube"
    elif [[ $i == *"w.tiktok.com"* ]]; then
        dvpath="Videos/TikTok"
        log_file="dv_tiktok"
    elif [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        error "Config file not found: $config_file"
        dvpath="Videos/Other"
        log_file="dv_other"
    fi

    [ ! -d "$Dir_Data/Media/$dvpath" ] && mkdir -p "$Dir_Data/Media/$dvpath"
    OK "Downloading: $count from ${#arrLinks[@]}"
    notify-send -a "DV" "Downloading" "$count from ${#arrLinks[@]}"
    yt-dlp -P "$Dir_Data/Media/$dvpath" --cookies-from-browser firefox --mark-watched --download-archive "$Dir_cache/$log_file" -f 'bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b' --concurrent-fragments 4 $i -o '%(title)s [%(id)s].%(ext)s' --no-warnings --no-simulate "${dv_vars[@]}"
    count=$((count + 1))
done

OK "Finished!"
notify-send -a "DV" Finished\! "${#arrLinks[@]} items done"
