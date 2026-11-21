# yroc-wp

Server tooling for the live **yrocconsulting.com** (WordPress on SiteGround, behind Sucuri).
The site's theme and content live in [yrocconsulting/staging](https://github.com/yrocconsulting/staging).

## Workflows (Actions tab)
- **Deploy to production**: pushes the theme and content from `yrocconsulting/staging` to the live site.
  Check the change on https://yrocstaging.yroc.host first. Pages edited in wp-admin are skipped unless
  *Overwrite pages* is ticked.
- **Publish new blog posts**: every 30 minutes. If the only changes in `yrocconsulting/staging` main since the
  last production deploy are blog posts (or tooling), it puts them live. Anything else (theme, pages) waits for
  a manual **Deploy to production**. `.deploy/production-sha` records which staging commit is live.
- **Weekly AI stats (production)**: Mondays 22:45 UTC (retry Tuesday 14:45), reads the newest ProRankTracker
  report from the shared Drive folder and updates the live homepage stats. The staging repo's job does the
  same for staging and also feeds the portal.
- **Clear Sucuri cache**: clears the firewall cache by hand. Deploy to production, Publish new blog posts and
  Weekly AI stats also clear it automatically after they change the site.
- **Go live**: the one-time rebuild of November 2026 (`backup`, `build`, `switch`, `rollback`).
  `rollback` puts the previous (old, infected) site back; use only in an emergency.
- **Pull from SiteGround**: copies the live theme into this repo (legacy).

## Server layout (SSH home)
- `www/yrocconsulting.com/public_html`: live site (fresh WordPress, table prefix `yc_`, PHP 8.4 via `.htaccess`)
- `www/yrocconsulting.com/public_html_old_*`: the old site, kept for reference, not web-accessible
- `yroc-backups/<timestamp>/`: backup of the old site (database + files)
- `yroc-bin/wp`: wp-cli running on PHP 8 (the server's default `wp` uses PHP 7.4)

Secrets: `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_PRIVATE_KEY`, `SSH_PASSPHRASE`, `SUCURI_API_KEY`, `SUCURI_API_SECRET`.
