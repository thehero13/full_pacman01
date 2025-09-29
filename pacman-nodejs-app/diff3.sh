GOOD=good; BAD=bad
FILES=(
  routes/highscores.js_customtags
  package.json
  metrics.js
  routes/highscores.js_waswokring
  routes/highscores.js
  public/index.html_b
  public/index.html
)

SUM=$(docker exec $GOOD sh -lc 'command -v md5sum || command -v sha256sum')

echo "== Checksums (good vs bad) =="
for f in "${FILES[@]}"; do
  echo "-- $f"
  docker exec "$GOOD" sh -lc "[ -f \"/usr/src/app/$f\" ] && $SUM \"/usr/src/app/$f\" || echo good:MISSING"
  docker exec "$BAD"  sh -lc "[ -f \"/usr/src/app/$f\" ] && $SUM \"/usr/src/app/$f\" || echo bad:MISSING"
done

# Pull and diff only those files that exist in both
WORK=/tmp/pac_focus; rm -rf "$WORK"; mkdir -p "$WORK"/{good,bad}
for f in "${FILES[@]}"; do
  mkdir -p "$WORK/good/$(dirname "$f")" "$WORK/bad/$(dirname "$f")"
  docker cp "$GOOD:/usr/src/app/$f" "$WORK/good/$f" 2>/dev/null || true
  docker cp "$BAD:/usr/src/app/$f"  "$WORK/bad/$f"  2>/dev/null || true
done
echo "== Per-file diffs =="
for f in "${FILES[@]}"; do
  if [ -f "$WORK/good/$f" ] && [ -f "$WORK/bad/$f" ]; then
    echo "--- $f ---"
    diff -u "$WORK/good/$f" "$WORK/bad/$f" || true
  fi
done

