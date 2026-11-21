#!/bin/bash
# Undo the switch: put the previous site back in public_html.
set -euo pipefail
SITE=$HOME/www/yrocconsulting.com
LIVE=$SITE/public_html
OLD=$(cat "$SITE/.yroc_previous_site")
[ -d "$OLD" ] || { echo "Previous site folder not found"; exit 1; }
rm -rf "$SITE/public_html_new"
mv "$LIVE" "$SITE/public_html_new"
mv "$OLD" "$LIVE"
rm -f "$SITE/.yroc_previous_site"
echo "Rolled back. The new site is parked in public_html_new."
