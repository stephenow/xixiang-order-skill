# Xixiang Order Skill

Codex skill for Xixiang enterprise meal ordering through the platform's direct API.

This repository is intended to be safe for an open-source workspace:

- no account, password, token, order number, address, company id, or company name is committed;
- local credentials live only in `.xixiang-credentials.json`, which is ignored by Git;
- raw browser snapshots and bundled frontend captures are ignored and should not be published.

## How It Works

The skill uses HTTPS API calls instead of browser automation:

1. Log in with an enterprise account.
2. Read available reservation dates and meal slots.
3. Fetch restaurants and dishes for each open slot.
4. Match explicit dish choices or prepare a recommendation for user confirmation.
5. Add the selected dish to the same meal-slot cart.
6. Verify cart, address, payment type, and order result.
7. Re-read the calendar to confirm the slot is marked as ordered.

Browser clicking is intentionally not part of the workflow anymore.

## Local Credentials

Create a local credential file from the template:

```powershell
Copy-Item .xixiang-credentials.example.json .xixiang-credentials.json
```

Then fill in your own enterprise account and password locally.

Never commit `.xixiang-credentials.json`.

## API Helper

List menus:

```powershell
.\scripts\xixiang-api.ps1 -Action List -StartDate 2026-06-01 -Days 5
```

Order one meal by keyword:

```powershell
.\scripts\xixiang-api.ps1 -Action Order -Date 2026-06-01 -Meal 2 -Keyword 牛肉
```

Meal values accept `2`/`lunch` for lunch and `4`/`dinner` for dinner. Chinese labels are also supported. By default the script submits "no tableware". Add `-NeedTableware` if utensils are needed.

The helper prints sanitized JSON. It does not print passwords or API tokens.

## Codex Usage Examples

```text
使用 xixiang-order-skill，查看下周工作日午餐菜单，先列出来让我选。
```

```text
使用 xixiang-order-skill，给我订今天午餐，关键词是牛肉。
```

```text
使用 xixiang-order-skill，检查下周哪些午餐还没订。
```

## Repository Layout

- `SKILL.md`: Codex-facing rules and workflow.
- `scripts/xixiang-api.ps1`: dependency-free PowerShell API helper.
- `references/api-protocol.md`: sanitized API protocol notes.
- `.xixiang-credentials.example.json`: local credential template.
- `SECURITY.md`: privacy and contribution rules.
