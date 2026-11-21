#!/bin/bash
# Back up the live site (files + database) to ~/yroc-backups/<timestamp>. Read-only on the site.
set -euo pipefail
SITE=$HOME/www/yrocconsulting.com
LIVE=$SITE/public_html
# --skip-plugins/--skip-themes: never execute the old site's (possibly infected) code.
OLDWP="wp --path=$LIVE --skip-plugins --skip-themes"

TS=$(date -u +%Y%m%d-%H%M%S)
B=$HOME/yroc-backups/$TS
mkdir -p "$B"
chmod 700 "$HOME/yroc-backups"

echo "== Sizes"
du -sh "$LIVE" "$LIVE/wp-content/uploads" 2>/dev/null || true

echo "== Database"
$OLDWP db export "$B/db.sql" --quiet
gzip "$B/db.sql"

echo "== Files"
tar -czf "$B/files.tar.gz" -C "$SITE" --exclude='public_html/wp-content/cache' public_html 2>"$B/tar-warnings.txt" \
  || echo "tar finished with warnings: $(wc -l < "$B/tar-warnings.txt") unreadable files skipped (quarantined malware)"

echo "$TS" > "$HOME/yroc-backups/LATEST"
echo "== Backup saved"
ls -lh "$B"

echo "== Top level of the live folder"
ls -la "$LIVE"
echo "== Cron jobs for this account"
crontab -l 2>/dev/null || echo "(none)"
