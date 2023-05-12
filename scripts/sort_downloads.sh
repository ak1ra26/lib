#!/bin/bash -i
init_i # initialize settings for interactive scripts

# Path to the downloads directory
DOWNLOAD_DIR="$Dir_Data/Media/Downloads"
VERBOSE=false

# Usage information function
function usage {
    echo "Usage: sort [-h|--help] [-v|--verbose] [-d|--dir <path>]"
    echo "Options:"
    echo "  -h, --help        Display this usage information"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -d, --dir <path>  Path to the downloads directory (default: $DOWNLOAD_DIR)"
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0;;
        -v|--verbose) VERBOSE=true; shift ;;
        -d|--dir) DOWNLOAD_DIR="$2"; shift ;;
        *) error "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

sort() {
  TEMP_FILE=$(mktemp)
  declare -A EXTENSIONS_MAP
  # Зображення
  for ext in "jpg" "jpeg" "png" "gif" "bmp" "tiff" "svg" "webp"; do EXTENSIONS_MAP["$ext"]="img"; done
  # HEIC
  for ext in "heic"; do EXTENSIONS_MAP["$ext"]="img/HEIC"; done
  # Документи
  for ext in "doc" "docx" "odt" "txt" "pdf" "xls" "xlsx" "ods" "ppt" "pptx" "odp"; do EXTENSIONS_MAP["$ext"]="docs"; done
  # Відео
  for ext in "avi" "mp4" "mkv" "flv" "mpeg" "mpg" "mov" "wmv" "m4v"; do EXTENSIONS_MAP["$ext"]="vid"; done
  # Музика
  for ext in "mp3" "wav" "flac" "aac" "m4a" "ogg"; do EXTENSIONS_MAP["$ext"]="music"; done

  find "$DOWNLOAD_DIR" -maxdepth 1 -type f |
  while read -r NEW_FILE; do
    if [[ $(basename "$NEW_FILE") != .* ]]; then
      FILE_EXT="$(echo "${NEW_FILE##*.}" | tr '[:upper:]' '[:lower:]')"
      FILE_TYPE_DIR="$DOWNLOAD_DIR/${EXTENSIONS_MAP["$FILE_EXT"]}"

      if [ -n "${EXTENSIONS_MAP["$FILE_EXT"]}" ]; then
        if [ ! -d "$FILE_TYPE_DIR" ]; then
          mkdir -p "$FILE_TYPE_DIR" && verbose "Created directory: $(basename "$FILE_TYPE_DIR")"
        fi

        if [ "$NEW_FILE" != "$FILE_TYPE_DIR/$(basename "$NEW_FILE")" ]; then
          mv "$NEW_FILE" "$FILE_TYPE_DIR"
          verbose "$(basename "$NEW_FILE") moved to $(basename "$FILE_TYPE_DIR")"
          echo "$(basename "$NEW_FILE");$(basename "$FILE_TYPE_DIR")" >> "$TEMP_FILE"
        fi
      fi
    fi
  done
  OK "Done!\n"
  { echo "Moved files:"; cat "$TEMP_FILE" | awk -F';' '{arr[$2]=arr[$2] "\n  - " $1} END {for (dir in arr) printf("%s:%s\n", dir, arr[dir])}'; }
  rm "$TEMP_FILE"

}

if [[ "$(ls -p "$DOWNLOAD_DIR" | grep -v /)" ]]; then sort; else error "No files found for sorting."; fi # якщо в директорії є файли, то запускає сортування

# Знаходимо та видаляємо порожні директорії
TEMP_FILE=$(mktemp)

find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 -type d |
while read -r EMPTY_DIR; do
  if [ -z "$(ls -A "$EMPTY_DIR")" ]; then
    rmdir "$EMPTY_DIR"
    verbose "${c_red}Removed empty directory:${NC} $(basename "$EMPTY_DIR")"
    echo "$(basename "$EMPTY_DIR")" >> "$TEMP_FILE"
  fi
done

# Виводимо інформацію про видалені директорії
if [ -s "$TEMP_FILE" ]; then
  echo "Removed directories:"
  cat "$TEMP_FILE" | while read -r line; do
    echo "  - $line"
  done
fi

# Видаляємо тимчасовий файл
rm "$TEMP_FILE"



