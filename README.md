# yroc-wp

Server tooling for the live **yrocconsulting.com** (WordPress on SiteGround, behind Sucuri).
The site's theme and content live in [yrocconsulting/staging](https://github.com/yrocconsulting/staging).

## Workflows (Actions tab)
- **Deploy to production**: pushes the theme and content from `yrocconsulting/staging` to the live site.
  Check the change on https://yrocstaging.yroc.host first. Pages edited in wp-admin are skipped unless
  *Overwrite pages* is ticked.
- **Go live**: the one-time rebuild of November 2026 (`backup`, `build`, `switch`, `rollback`).
  `rollback` puts the previous (old, infected) site back; use only in an emergency.
- **Pull from SiteGround**: copies the live theme into this repo (legacy).

## Server layout (SSH home)
- `www/yrocconsulting.com/public_html`: live site (fresh WordPress, table prefix `yc_`, PHP 8.4 via `.htaccess`)
- `www/yrocconsulting.com/public_html_old_*`: the old site, kept for reference, not web-accessible
- `yroc-backups/<timestamp>/`: backup of the old site (database + files)
- `yroc-bin/wp`: wp-cli running on PHP 8 (the server's default `wp` uses PHP 7.4)

Secrets: `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_PRIVATE_KEY`, `SSH_PASSPHRASE`.
