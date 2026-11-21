#!/bin/bash
# Put the new build live: public_html -> public_html_old_<ts>, public_html_new -> public_html.
set -euo pipefail
export PATH="$HOME/yroc-bin:$PATH"   # PHP 8 wp-cli installed by build.sh
SITE=$HOME/www/yrocconsulting.com
LIVE=$SITE/public_html
NEW=$SITE/public_html_new
[ -f "$NEW/wp-config.php" ] || { echo "No new build found; run the build step first"; exit 1; }
[ -f "$HOME/yroc-backups/LATEST" ] || { echo "No backup found; run the backup step first"; exit 1; }

# Keep search-engine verification files and .well-known (no PHP).
for f in "$LIVE"/google*.html "$LIVE"/BingSiteAuth.xml "$LIVE"/ads.txt; do
  [ -f "$f" ] && [ ! -e "$NEW/$(basename "$f")" ] && cp -a "$f" "$NEW/" && echo "kept $(basename "$f")"
done
[ -d "$LIVE/.well-known" ] && rsync -a --exclude '*.php' "$LIVE/.well-known/" "$NEW/.well-known/" && echo "kept .well-known"

OLD=$SITE/public_html_old_$(date -u +%Y%m%d-%H%M%S)
mv "$LIVE" "$OLD"
mv "$NEW" "$LIVE"
echo "$OLD" > "$SITE/.yroc_previous_site"
echo "Live folder switched. Old site kept at $(basename "$OLD")"
wp --path="$LIVE" cache flush
wp --path="$LIVE" sg purge 2>/dev/null || true
