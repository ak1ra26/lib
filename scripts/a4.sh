#!/bin/bash -i
init_i # initialize settings for interactive scripts
# standart configuration
a4dir=$Dir_Data/Projects/A4/;
nikkidir=$Dir_Data/Projects/E日記/
a4editor=kate;
a4format="%y%m-%d"; # %y%m-%d is default
nikkiformat="%y%m-%d"; # %y%m-%d is default
# connect config file if it exists
if test -f /media/Data/Mega/sh/config/sh.cfg ; then . /media/Data/Mega/sh/config/sh.cfg;fi

concatfiles(){
files=($a4dir/2???-??);
if [ "${#files[@]}" -gt "2" ]; then
a4tmp=$a4dir/a4tmp
touch $a4tmp
for file4 in "${files[@]::${#files[@]}-1}"; do
echo "[${file4: -7}]" >> $a4tmp # зробити один файл "archive" і до нього ось так все прописувать, а не через tmp, але робить backup усіх файлів.
echo "{" >> $a4tmp
cat $file4 >> $a4tmp
echo "}" >> $a4tmp
echo ""  >> $a4tmp
rm -rf $file4
done
cat $a4tmp >> $a4dir/Archive
rm -rf $a4tmp
fi
}

concat2сс(){
files=($nikkidir/2???-??);
if [ "${#files[@]}" -gt "2" ]; then
nikkitmp=$nikkidir/nikkitmp
touch $nikkitmp
for file4 in "${files[@]::${#files[@]}-1}"; do
echo "[${file4: -7}]" >> $nikkitmp
echo "{" >> $nikkitmp
cat $file4 >> $nikkitmp
echo "}" >> $nikkitmp
echo ""  >> $nikkitmp
rm -rf $file4
done
cat $nikkitmp >> $nikkidir/E日記
rm -rf $nikkitmp
fi
}

### Check for dir, if not found create it using the mkdir ##
[ ! -d "$a4dir" ] && mkdir -p "$a4dir"
[ ! -d "${a4dir}warg" ] && mkdir -p "${a4dir}warg"

# Показує список файлів, якщо є атрибут -l.
[[ "$1" =~ ^-l ]] && ls "$a4dir" && exit

file="$a4dir`date +"$a4format"`"

# Відкриває файл за $1 день до поточної дати.
if [[ $1 == ?(-)+([0-9]) ]];then file="$a4dir`date --date="$1"' day' +"$a4format"`";$a4editor $file & exit;fi
if [[ "$1" == ?(-)+("shift")?(s) ]];then $a4editor ${a4dir}warg/shifts & exit;fi
if [[ "$1" == ?(-)+("factorio")?(s) ]];then $a4editor ${a4dir}warg/factorio & exit;fi
if [[ "$1" == ?(-)+("nikki") ]];then file="$nikkidir""`date +"$nikkiformat"`";$a4editor $file && concat2сс & exit;fi

# Створює файл, якщо ще не існує файлу А4 на сьогоднішню дату і змінна не визначена.
[ -z ${1+x} ] && [ ! -f "$file" ] && touch "$file"

# Запускає редактор та необхідний файл.
$a4editor $file & concatfiles && exit

# __________________________________
# Ідеї
# __________________________________
# Видаляє файли, які містять менше 4 символів перед об'єднанням, але щоб це не стосувалося поточного дня.
# Для 5 байтів це: find . -type f -size -5c -exec rm '{}' ';'
# Але це з поточної директорії.

# kwrite прибрав, бо з ним якась помилка була. На усяк випадок, щоб не втрачати файли.
