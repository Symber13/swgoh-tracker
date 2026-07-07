#!/bin/sh
set -eu

PORT="${PORT:-8080}"
KEEPALIVE_INTERVAL="${KEEPALIVE_INTERVAL:-420}"
tracker_pid=""

mkdir -p /app/www
printf '<!doctype html>\n<html lang="en">\n<head><meta charset="utf-8"><title>SWGOH Arena Tracker</title></head>\n<body><h1>SWGOH Arena Tracker</h1><p>The service is running.</p></body>\n</html>\n' > /app/www/index.html
printf 'ok\n' > /app/www/healthz

start_tracker() {
  if [ -n "$tracker_pid" ] && kill -0 "$tracker_pid" 2>/dev/null; then
    return 0
  fi

  echo "Starting tracker process." >&2
  dotnet /app/SimpleTracker.dll > /tmp/swgoh-tracker.log 2>&1 &
  tracker_pid=$!
}

python3 -m http.server "$PORT" --directory /app/www > /tmp/httpd.log 2>&1 &
httpd_pid=$!

cleanup() {
  trap - TERM INT
  kill "$httpd_pid" "$tracker_pid" 2>/dev/null || true
  wait "$httpd_pid" "$tracker_pid" 2>/dev/null || true
  exit 0
}
trap cleanup TERM INT

start_tracker

(
  while true; do
    sleep "$KEEPALIVE_INTERVAL"
    wget -q -O /dev/null "http://127.0.0.1:${PORT}/healthz" >/dev/null 2>&1 || true
  done
) &
keepalive_pid=$!

while true; do
  if ! kill -0 "$httpd_pid" 2>/dev/null; then
    echo "HTTP listener exited unexpectedly." >&2
    exit 1
  fi

  if [ -n "$tracker_pid" ] && ! kill -0 "$tracker_pid" 2>/dev/null; then
    start_tracker
  fi

  sleep 10
done
