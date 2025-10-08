#!/bin/bash

if [ -z "$1" ]; then
  echo "Penggunaan: $0 <nama_user>"
  exit 1
fi

USER=$1
rss_total=0   # RAM fisik (VmRSS)
swap_total=0  # RAM swap
cpu_total=0   # CPU total (dari semua proses user)

# Ambil jumlah core dan kecepatan CPU (GHz)
cpu_cores=$(nproc)
cpu_mhz=$(awk '/cpu MHz/ {print $4; exit}' /proc/cpuinfo)
cpu_speed=$(awk "BEGIN {print $cpu_mhz / 1000}")  # Konversi ke GHz

# Loop semua PID milik user
for pid in $(pgrep -u "$USER"); do
  status_file="/proc/$pid/status"
  [ -r "$status_file" ] || continue

  # Ambil VmRSS dan VmSwap (dalam KB)
  rss=$(awk '/VmRSS:/ {print $2}' "$status_file")
  swap=$(awk '/VmSwap:/ {print $2}' "$status_file")
  rss=${rss:-0}
  swap=${swap:-0}

  rss_total=$((rss_total + rss))
  swap_total=$((swap_total + swap))

  # Ambil CPU usage proses (%)
  cpu=$(ps -p "$pid" -o %cpu= | tr -d '[:space:]')
  cpu=${cpu:-0}

  # Tambahkan ke total CPU (floating point)
  cpu_total=$(awk "BEGIN {print $cpu_total + $cpu}")
done

# Hitung total penggunaan GHz (berdasarkan semua core)
used_ghz=$(awk "BEGIN {print ($cpu_total / 100) * $cpu_cores * $cpu_speed}")

# Total RAM (RSS + SWAP) dalam MB
total_ram_mb=$(( (rss_total + swap_total) / 1024 ))

# Output JSON
echo "{
  \"user\": \"$USER\",
  \"cpu_ghz\": $(printf '%.2f' "$used_ghz"),
  \"ram_mb\": $total_ram_mb
}"