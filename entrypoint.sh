#!/bin/sh
set -eu

PORT="${PORT:-8080}"
KEEPALIVE_INTERVAL="${KEEPALIVE_INTERVAL:-420}"
KEEPALIVE_URL="${KEEPALIVE_URL:-http://127.0.0.1:${PORT}/}"
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

keepalive_request() {
  if command -v wget >/dev/null 2>&1; then
    wget -q -T 10 -O /dev/null "$KEEPALIVE_URL"
  else
    python3 -c "import urllib.request,sys; urllib.request.urlopen('$KEEPALIVE_URL', timeout=10).read(); sys.exit(0)" >/dev/null 2>&1
  fi
}

start_tracker

(
  while true; do
    keepalive_request >/dev/null 2>&1 || true
    sleep "$KEEPALIVE_INTERVAL"
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
