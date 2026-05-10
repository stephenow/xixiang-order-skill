# Ordering Workflow Reference

This reference captures observed behavior for `https://wechat.platform.xixiang000.com/`.

## Login

- The login page title is usually `熙香企业订餐平台`.
- Fields:
  - account placeholder: `请输入您的账号`
  - password placeholder: `请输入您的密码`
- There are two buttons with weak accessible names. The first button is enterprise account login (`企业账号登录`), and the second is WeChat quick login.
- If text locators cannot find `企业账号登录`, use the visible DOM button order or screen position, but only after verifying the login screen visually.

## Home Page

- After login, the home page shows a horizontal date carousel and bottom tabs:
  - `点餐`
  - `订单`
  - `我的`
- Select a date first, then read cards for meal slots.
- Lunch card usually shows `00:00~10:00` and `午餐`.
- Dinner card usually shows `00:00~16:00` and `晚餐`.
- Status appears on the right:
  - `已点餐`: already ordered, dish name and `x1` should be visible.
  - `未点餐`: open for ordering.
- Do not use direct goods URLs as the primary discovery path. Click from the home card because restaurant/menu data can differ by card context and current app state.

## Menu Discovery

Open each `未点餐` lunch/dinner card from the home page and record:

- date
- meal type
- restaurant
- visible dish options
- any already selected quantity

The goods page has duplicated sections such as `热销菜` and a category section. The same dish can appear twice on the page; selecting once can update both duplicate rows.

## Selecting A Dish

Preferred approach:

1. Confirm the goods page contains the expected dish text.
2. Locate the plus icon for that dish.
3. Click plus once.
4. Confirm the cart badge or row quantity changes to `1`.

Observed fallback:

- Plus controls can be icon-font `i` elements with empty text.
- In pages where CSS class names are unavailable, `locator('i')` can expose the icons. Use `count()` first.
- For a two-option page:
  - `i.nth(0)` often selects the first dish.
  - `i.nth(1)` often selects the second dish.
- Avoid relying only on x/y coordinates. Coordinates vary by page layout and scroll position. If coordinates are necessary, take a screenshot first and verify the plus icon position.

If `选好了/Next` shows `请您先添加商品后再下单!`, dismiss the alert, re-open/inspect the goods page, and click the plus control using a more reliable locator.

## Cart And Submit

After clicking `选好了/Next`, the cart URL usually looks like:

`#/shopcart?date=YYYY-MM-DD&mt=<2-or-4>&companyId=1190`

Check before submitting:

- restaurant name
- date and meal type
- selected dish
- `1份`
- selected address, observed example: `世纪财富广场16F`
- meal requirement, usually `不需要餐具`

If a modal asks `请选择是否需要餐具`, choose `不需要餐具` unless the user asked for utensils.

Then click `确认支付`. A successful submit typically navigates to the order tab or shows order categories such as:

- `今日订单`
- `预定订单`
- `历史订单`
- `线下订单`

## Verification

Return to `#/`, select each target date again, and verify each target slot shows:

- `已点餐`
- expected dish name
- `x1`

Report any mismatch or slot that still shows `未点餐`.

## Confirmation Policy

Explicit user choices:

- If the user says to order specific dishes, complete the transaction and then verify.

Preference-based choices:

- Collect all available options first.
- Make proposed choices.
- Ask the user to confirm the full list before clicking any plus controls or submitting.

Potentially risky actions:

- Do not replace, cancel, or increase quantities unless the user explicitly requested that exact action.
- If the platform shows any unexpected payment amount, address mismatch, unavailable dish, or duplicate existing order, stop and ask the user.
