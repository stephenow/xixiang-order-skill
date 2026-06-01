# Security And Privacy

This repository is intended for open-source sharing. Keep it free of personal and company-specific data.

Do not commit:

- `.xixiang-credentials.json`;
- API tokens, cookies, or session files;
- phone numbers, names, company names, company ids, addresses, or order numbers;
- raw browser snapshots, screenshots, frontend bundles, or captured page state.

Use HTTPS for all API calls. Do not send credentials or tokens over plain HTTP.

If a secret is accidentally committed, rotate the password or token first, then remove the secret from Git history before pushing.
