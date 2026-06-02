---
name: xixiang-order-skill
description: Use this skill when helping a user inspect menus and place meal orders on the Xixiang enterprise ordering platform through the direct HTTPS API. Use it for logging in with user-provided credentials, listing available lunch/dinner options, matching explicit dish choices, preparing recommendation tables, submitting confirmed orders, and verifying order status without browser automation.
---

# Xixiang Order Skill

This skill is API-only. Do not use browser automation for normal menu lookup, ordering, or verification.

## Privacy Rules

- Never print, commit, or push account passwords, API tokens, cookies, company names, company ids, addresses, phone numbers, or order numbers unless the user explicitly needs the order number in the current conversation.
- Local credentials may be stored only when the user explicitly asks. Store them in `.xixiang-credentials.json`; this file is ignored by Git.
- Use HTTPS API URLs only. Do not transmit credentials or tokens over plain HTTP.
- Do not publish raw frontend bundles, DOM snapshots, screenshots, or captured page state.

## Ordering Rules

- Ordering is a real-world transaction.
- If the user gives explicit meal choices and asks to order, submit those exact meals and then verify the result.
- If the agent selects meals from preferences, show a concise table and wait for user confirmation before adding to cart or submitting.
- Do not replace, cancel, or increase an existing order unless the user explicitly requests that exact action.
- If an endpoint returns an unexpected payment requirement, missing address, closed slot, sold-out dish, duplicate order, or `code != 1`, stop and report the message.
- Default to no tableware unless the user asks for utensils.

## API Workflow

1. Read `references/api-protocol.md`.
2. Log in with `POST /login/` and keep `api_token` only in memory.
3. Use `GET /allReserveDate/` and `GET /companyIndex/` to discover selectable dates and meal slots.
4. For open slots, derive `companyId` and numeric `menuType` from `companyIndex/`.
5. Use `GET /businessIndex/` and `GET /getCookbook/` to list restaurant and dish options.
6. Match exact user keywords against `cookbook.menu_name`. If ambiguous, ask the user to choose.
7. For a confirmed order, clear or verify only the target slot cart, then `POST /cart/add/`.
8. Verify the cart with `GET /lists/` and payment mode with `GET /cart/total/`.
9. Fetch an address with `GET /userAddress/`.
10. Submit with `POST /order/add/`.
11. Re-read `companyIndex/` and confirm the slot is `status = 1` with the expected dish name and quantity.

## Local Helper

Prefer the repository helper for repeatable API work:

```powershell
.\scripts\xixiang-api.ps1 -Action List -StartDate <YYYY-MM-DD> -Days 5
.\scripts\xixiang-api.ps1 -Action Order -Date <YYYY-MM-DD> -Meal 2 -Keyword <dish-keyword>
```

The helper reads `.xixiang-credentials.json` and prints sanitized JSON only.
