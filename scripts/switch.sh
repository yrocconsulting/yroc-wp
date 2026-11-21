#!/bin/bash
# Put the new build live: public_html -> public_html_old_<ts>, public_html_new -> public_html.
set -euo pipefail
export PATH="$HOME/yroc-bin:$PATH"   # PHP 8 wp-cli installed by build.sh
SITE=$HOME/www/yrocconsulting.com
LIVE=$SITE/public_html
NEW=$SITE/public_html_new
[ -f "$NEW/wp-config.php" ] || { echo "No new build found; run the build step first"; exit 1; }
[ -f "$HOME/yroc-backups/LATEST" ] || { echo "No backup found; run the backup step first"; exit 1; }

# 1. Pick a PHP 8 version the web server actually runs (tested in a throwaway folder).
HANDLER=""
for v in 84 85 83 86 82; do
  [ -d "/usr/local/php$v" ] || continue
  T="yroc-phptest-$RANDOM$RANDOM"
  mkdir "$LIVE/$T"
  echo "AddHandler application/x-httpd-php$v .php" > "$LIVE/$T/.htaccess"
  echo '<?php echo "PHPOK " . PHP_VERSION;' > "$LIVE/$T/v.php"
  OUT=$(curl -s --max-time 20 "https://yrocconsulting.com/$T/v.php?$RANDOM" || true)
  rm -rf "${LIVE:?}/$T"
  echo "php$v: ${OUT:0:40}"
  if [[ "$OUT" == "PHPOK 8."* ]]; then HANDLER="application/x-httpd-php$v"; break; fi
done
[ -n "$HANDLER" ] || { echo "Could not confirm a working PHP 8 handler; not switching"; exit 1; }
echo "Using $HANDLER"

# 2. Final .htaccess: HTTPS redirect (as before), WordPress rules, PHP 8.
{
  cat <<'HT'
# BEGIN Force HTTPS
<IfModule mod_rewrite.c>
RewriteEngine on
RewriteCond %{HTTP:X-Forwarded-Proto} !https
RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]
</IfModule>
# END Force HTTPS
HT
  grep -v '^AddHandler' "$NEW/.htaccess"
  echo "AddHandler $HANDLER .php"
} > "$NEW/.htaccess.tmp" && mv "$NEW/.htaccess.tmp" "$NEW/.htaccess"

# 3. Carry over static files that are still in use (no PHP).
for f in ai-challenge.html repmgmt.html google*.html BingSiteAuth.xml ads.txt; do
  [ -f "$LIVE/$f" ] && [ ! -e "$NEW/$f" ] && cp -a "$LIVE/$f" "$NEW/" && echo "kept $f"
done
[ -d "$LIVE/.well-known" ] && rsync -a --exclude '*.php' "$LIVE/.well-known/" "$NEW/.well-known/" && echo "kept .well-known"

# 4. Switch.
OLD=$SITE/public_html_old_$(date -u +%Y%m%d-%H%M%S)
mv "$LIVE" "$OLD"
mv "$NEW" "$LIVE"
echo "$OLD" > "$SITE/.yroc_previous_site"
echo "Live folder switched. Old site kept at $(basename "$OLD") (not web-accessible)"
wp --path="$LIVE" cache flush
wp --path="$LIVE" sg purge 2>/dev/null || true
