# ---------- CONFIG ----------
GOOD_CTR=good
BAD_CTR=bad
WORK=/tmp/pac_diff; rm -rf "$WORK"; mkdir -p "$WORK"/{good,bad}

# ---------- DISCOVER PORTS ----------
GOOD_PORT=$(docker port "$GOOD_CTR" 2>/dev/null | awk -F: '/8080\/tcp/ {print $2; exit}')
BAD_PORT=$(docker port "$BAD_CTR"  2>/dev/null | awk -F: '/8080\/tcp/ {print $2; exit}')
echo "[ports] good:$GOOD_PORT  bad:$BAD_PORT"

# ---------- QUICK GREPS INSIDE CONTAINERS (fast, HTML only) ----------
echo "=== Grep: includes & init (good) ==="
docker exec "$GOOD_CTR" sh -lc 'grep -R --include="*.html" -n -m1 -E "splunk-otel-web(-session-recorder)?\.js|SplunkRum\.init|SplunkSessionRecorder\.init" /usr/src/app /usr/share/nginx/html /app 2>/dev/null || true'
echo "=== Grep: includes & init (bad) ==="
docker exec "$BAD_CTR"  sh -lc 'grep -R --include="*.html" -n -m1 -E "splunk-otel-web(-session-recorder)?\.js|SplunkRum\.init|SplunkSessionRecorder\.init" /usr/src/app /usr/share/nginx/html /app 2>/dev/null || true'

# ---------- FETCH WHAT THE BROWSER GETS ----------
curl -sI "http://localhost:$GOOD_PORT/" > "$WORK/hdr.good.txt"
curl -sI "http://localhost:$BAD_PORT/"  > "$WORK/hdr.bad.txt"
curl -s  "http://localhost:$GOOD_PORT/" > "$WORK/index.good.html"
curl -s  "http://localhost:$BAD_PORT/"  > "$WORK/index.bad.html"

echo "=== Response header diff (CSP etc.) ==="
diff -u "$WORK/hdr.good.txt" "$WORK/hdr.bad.txt" || true

echo "=== Top-level HTML diff (as-served) ==="
diff -u "$WORK/index.good.html" "$WORK/index.bad.html" || true

# ---------- COPY LIKELY APP FILES (shallow, skip node_modules) ----------
CANDS="/usr/src/app /usr/src/app/public /usr/share/nginx/html /app /var/www/html"
for c in "$GOOD_CTR" "$BAD_CTR"; do
  out="$WORK/$( [ "$c" = "$GOOD_CTR" ] && echo good || echo bad )"
  docker exec "$c" sh -lc '
    set -e
    for d in '"$CANDS"'; do
      [ -d "$d" ] || continue
      find "$d" -maxdepth 2 -type f ! -path "*/node_modules/*" -print
    done' | sed 's#^/##' | while read -r f; do
      mkdir -p "$out/$(dirname "$f")"
      docker cp "$c:/$f" "$out/$f" 2>/dev/null || true
    done
done

echo "=== File tree diff (HTML/JS/CSS likely roots) ==="
diff -ru \
  --exclude=node_modules --exclude=.git --exclude=*.map \
  --exclude=*.png --exclude=*.jpg --exclude=*.jpeg --exclude=*.svg \
  "$WORK/good" "$WORK/bad" || true

echo
echo "Artifacts under: $WORK"

