#!/bin/bash

# Функція для встановлення частоти на всіх ядрах
set_freq() {
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo "$1" | sudo tee "$cpu/cpufreq/scaling_max_freq"
  done
}

# Якщо аргумент не переданий
if [ -z "$1" ]; then
  all_max=true
  MIN=1600000

  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    CUR=$(cat "$cpu/cpufreq/scaling_max_freq")
    MAX=$(cat "$cpu/cpufreq/cpuinfo_max_freq")

    if [ "$CUR" -ne "$MAX" ]; then
      all_max=false
      break
    fi
  done

  if [ "$all_max" = true ]; then
    set_freq "$MIN"
  else
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
      MAX=$(cat "$cpu/cpufreq/cpuinfo_max_freq")
      echo "$MAX" | sudo tee "$cpu/cpufreq/scaling_max_freq"
    done
  fi
  exit 0
fi

MAX_KHZ=$(< /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
MAX_GHZ=$(awk "BEGIN {printf \"%.1f\", $MAX_KHZ/1000000}")

case $1 in
  min)
    set_freq 1600000
    ;;
  low)
    set_freq 2100000
    ;;
  low+)
    set_freq 2300000
    ;;
  mid)
    set_freq 2900000
    ;;
  mid+)
    set_freq 3200000
    ;;
  mid++)
    set_freq 3300000
    ;;
  high-)
    set_freq 3400000
    ;;
  high)
    set_freq 3500000
    ;;
  high+)
    set_freq 3600000
    ;;
  unlim)
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
      MAX=$(cat "$cpu/cpufreq/cpuinfo_max_freq")
      echo "$MAX" | sudo tee "$cpu/cpufreq/scaling_max_freq"
    done
    ;;
  *)
    echo "Usage: $0 {min|low|mid|high|unlim}"
    echo
    echo "  min       – 1.6 GHz (для нод, коли сплю)"
    echo "  low       – 2.1 GHz (легке навантаження, браузер, базові задачі)"
    echo "  low+      – 2.3 GHz (браузер у 2 вікна)"
    echo "  mid       – 2.9 GHz (баланс між швидкодією і температурою)"
    echo "  mid+      – 3.2 GHz (оптимально для двох людей за одним ПК)"
    echo "  mid+      – 3.2 GHz"
    echo "  mid++     – 3.3 GHz (The Sims 4)"
    echo "  high-     – 3.4 GHz"
    echo "  high      – 3.5 GHz (для більшого навантаження)"
    echo "  high+     – 3.6 GHz"
    echo "  unlim     – ${MAX_GHZ} GHz (повна частота CPU)"
    exit 1
    ;;
esac
