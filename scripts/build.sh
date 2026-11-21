#!/bin/bash
# Build a clean WordPress for yrocconsulting.com in public_html_new, from files uploaded to ~/yroc-golive.
# The live site keeps running untouched. Usage: build.sh <admin-email>
set -euo pipefail
ADMIN_EMAIL=$1
SITE=$HOME/www/yrocconsulting.com
LIVE=$SITE/public_html
NEW=$SITE/public_html_new
SRC=$HOME/yroc-golive
PREFIX=yc_
OLDWP="wp --path=$LIVE --skip-plugins --skip-themes"
WP="wp --path=$NEW"

php -v | head -n1
[ -f "$HOME/yroc-backups/LATEST" ] || { echo "Run the backup step first"; exit 1; }

OLD_PREFIX=$($OLDWP config get table_prefix)
[ "$OLD_PREFIX" != "$PREFIX" ] || { echo "Old site already uses prefix $PREFIX, refusing"; exit 1; }

# Re-runs: drop only the tables of the previous attempt (prefix yc_), then start over.
if [ -f "$NEW/wp-config.php" ]; then
  [ "$($WP config get table_prefix)" = "$PREFIX" ] || { echo "Unexpected wp-config in $NEW"; exit 1; }
  echo "Removing previous build attempt"
  $WP db clean --yes --quiet
fi
rm -rf "$NEW"
mkdir -p "$NEW"

echo "== WordPress core"
$WP core download --quiet
$WP config create \
  --dbname="$($OLDWP config get DB_NAME)" \
  --dbuser="$($OLDWP config get DB_USER)" \
  --dbpass="$($OLDWP config get DB_PASSWORD)" \
  --dbhost="$($OLDWP config get DB_HOST)" \
  --dbprefix=$PREFIX --skip-check --quiet --extra-php <<'PHP'
if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && 'https' === $_SERVER['HTTP_X_FORWARDED_PROTO'] ) {
	$_SERVER['HTTPS'] = 'on';
}
define( 'DISALLOW_FILE_EDIT', true );
define( 'FORCE_SSL_ADMIN', true );
PHP
[ -z "$($WP db query "SHOW TABLES LIKE '${PREFIX//_/\\_}%'" --skip-column-names)" ] || { echo "Tables with prefix $PREFIX already exist, refusing"; exit 1; }

$WP core install --url=https://yrocconsulting.com --title="Yroc Consulting" \
  --admin_user=bradley --admin_email="$ADMIN_EMAIL" \
  --admin_password="$(openssl rand -base64 30)" --skip-email --quiet
$WP option update timezone_string America/Chicago --quiet
$WP plugin delete akismet hello --quiet || true
$WP plugin install sg-cachepress --activate --quiet || echo "SiteGround Optimizer not installed"

echo "== Theme and content"
mkdir -p "$NEW/wp-content/themes/yroc"
cp -a "$SRC/theme/yroc/." "$NEW/wp-content/themes/yroc/"
$WP theme activate yroc
$WP theme delete twentytwentythree twentytwentyfour --quiet || true
$WP eval 'wp_get_theme()->delete_pattern_cache();'
$WP rewrite structure '/%category%/%postname%/' --hard
YROC_FORCE=1 $WP eval-file "$SRC/import.php" "$SRC/content"
$WP cron event run yroc_reviews_sync >/dev/null 2>&1 || true
$WP cache flush

echo "== Result"
echo "home: $($WP option get home)  search engines allowed: $($WP option get blog_public)"
echo "pages: $($WP post list --post_type=page --format=count)  posts: $($WP post list --post_type=post --format=count)  images: $($WP post list --post_type=attachment --format=count)"
echo "posts with images still pending: $($WP post list --post_type=any --meta_key=_yroc_media_pending --format=count)"
$WP user list --fields=user_login,user_email,roles
$WP plugin list
[ -f "$NEW/.htaccess" ] && cat "$NEW/.htaccess"
echo "== Top-level items in the old site that are not in the new one"
comm -23 <(ls -A "$LIVE" | sort) <(ls -A "$NEW" | sort)
