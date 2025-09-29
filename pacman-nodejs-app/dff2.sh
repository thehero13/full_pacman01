GOOD=good
BAD=bad
SUM=$(docker exec $GOOD sh -lc 'command -v md5sum || command -v sha256sum')

for f in "${FILES[@]}"; do
  echo "— $f"
  docker exec "$GOOD" sh -lc "[ -f \"/usr/src/app/${f#./}\" ] && $SUM \"/usr/src/app/${f#./}\" || echo MISSING"
  docker exec "$BAD"  sh -lc "[ -f \"/usr/src/app/${f#./}\" ] && $SUM \"/usr/src/app/${f#./}\" || echo MISSING"
  echo
done

