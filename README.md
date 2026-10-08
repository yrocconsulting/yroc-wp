# yroc-wp

Code for yrocconsulting.com (WordPress on SiteGround).

- `wp-content/themes`, `wp-content/mu-plugins`: copied from the live site by the
  **Pull from SiteGround** workflow (Actions → Pull from SiteGround → Run workflow).
- `site-info/`: WordPress version, theme and plugin lists at the time of the last pull.

The workflows use the repo secrets `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_PRIVATE_KEY`.
