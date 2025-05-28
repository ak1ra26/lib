# cpu-limiter.sh
#!/bin/bash

case $1 in
  low)
    FREQ=2100000
    ;;
  mid)
    FREQ=2300000
    ;;
  high)
    FREQ=2500000
    ;;
  unlimited)
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
      MAX=$(cat "$cpu/cpufreq/cpuinfo_max_freq")
      echo $MAX | sudo tee "$cpu/cpufreq/scaling_max_freq"
    done
    exit 0
    ;;
  *)
    echo "Usage: $0 {low|mid|high|unlimited}"
    echo
    echo "  low       – обмежити до 2.1 GHz (мінімальне тепло, але ще придатне для браузера)"
    echo "  mid       – обмежити до 2.3 GHz (баланс між швидкодією і температурою)"
    echo "  high      – обмежити до 2.5 GHz (для більшого навантаження, якщо не гріється)"
    echo "  unlimited – зняти обмеження і дозволити повну частоту CPU"
    exit 1
    ;;
esac

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo $FREQ | sudo tee "$cpu/cpufreq/scaling_max_freq"
done
