---
name: xixiang-order-skill
description: Use this skill when helping a user order meals on the Xixiang enterprise ordering platform at wechat.platform.xixiang000.com, including logging in with user-provided enterprise account credentials, inspecting weekly lunch and dinner menus, choosing meals from explicit instructions or food preferences, asking the user to confirm AI-selected choices before ordering, submitting one meal, selected meals, or a full week of meals, and verifying completed orders.
---

# Xixiang Order Skill

Use browser automation for the Xixiang enterprise ordering platform. Never store or invent credentials. Ask the user to provide the enterprise account username and password for the current session when needed.

## Operating Rules

- Use the Browser/in-app browser when available.
- Treat ordering as a real-world transaction. If the user gave explicit meal choices and asked you to order, proceed through confirmation and payment screens. If you selected meals from preferences, summarize all proposed choices and wait for user confirmation before submitting.
- Default scope is the current or next available work week and all available lunch/dinner slots unless the user asks for specific dates, meals, or one-off changes.
- Do not change already ordered meals unless the user explicitly asks to replace or cancel them.
- Prefer "需要餐具" when the platform prompts for utensils unless the user says otherwise.
- After submitting, return to the home ordering calendar and verify each target slot shows "已点餐" with the expected dish name.
- Keep notes about page behavior and any changed selectors so the skill can be improved later.

## Workflow

1. Open `https://wechat.platform.xixiang000.com/`.
2. Log in via "企业账号登录" using credentials provided by the user for this session.
3. On the home page, inspect the date carousel for the target week. Gray weekend dates may be unavailable.
4. For each target day, click the date, then inspect the lunch and dinner cards:
   - "已点餐" means already ordered. Record the dish and skip unless replacement was requested.
   - "未点餐" means open for ordering. Click the card to open its goods page.
5. On the goods page, collect visible dish names and restaurant names. If the user gave preferences rather than exact choices, choose one option per open meal using the selection policy below, then ask for confirmation.
6. Select a dish by clicking its plus control once. Use DOM locators when stable; if not, use the icon sequence described in `references/ordering-workflow.md`.
7. Click `选好了/Next`.
8. On the cart page, verify date, meal type, dish, quantity `1份`, and address.
9. Select or confirm "需要餐具" if prompted.
10. Click `确认支付`.
11. Verify the target slot on the home page shows `已点餐` and the expected dish.

## Selection Policy

When the user gives preferences instead of exact meals:

- Prefer explicit likes first, then balanced variety across the week.
- Avoid user-stated dislikes, allergens, spicy food, fried food, seafood, beef, pork, or fast food as requested.
- Do not assume dietary restrictions. Ask only if the preference is too ambiguous or risk-sensitive.
- Avoid repeating the same dish category too often when reasonable alternatives exist.
- If all options conflict with stated preferences, present the conflict and ask the user to choose.

Before submitting AI-selected meals, show a concise table with date, meal, chosen dish, and reason.

## Reference

Read `references/ordering-workflow.md` when performing browser automation, recovering from selector issues, or writing/updating automation notes for this platform.
