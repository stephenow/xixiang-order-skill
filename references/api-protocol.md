# Xixiang Ordering API Protocol

Sanitized direct-API notes for Codex and local automation. Do not add real accounts, passwords, tokens, company names, addresses, company ids, order numbers, or captured browser state to this document.

## Safety Rules

- Use HTTPS only: `https://api.platform.xixiang000.com/`.
- Keep `api_token` in memory for the current run only.
- Store local credentials only in `.xixiang-credentials.json`, which is ignored by Git.
- Treat cart and order endpoints as real-world transactions.
- Stop on unexpected payment, missing address, sold-out dish, closed slot, duplicate order, or `code != 1`.

## Transport

- `GET` parameters are passed in the query string.
- `POST` bodies are `application/x-www-form-urlencoded`.
- Authentication uses the `api_token` query parameter, not an Authorization header.
- Success usually returns `{ "code": 1, "message": "...", "data": ... }`.

## Authentication

```http
POST /login/
Content-Type: application/x-www-form-urlencoded
```

Body:

```text
phone=<account>&password=<password>&qrcodeValue=&openid=
```

Successful `data` includes `api_token`.

## Calendar

```http
GET /allReserveDate/?api_token=<token>
GET /companyIndex/?api_token=<token>&menu_date=<YYYY-MM-DD>
```

`companyIndex/` returns one entry per company/meal slot. Use top-level fields for follow-up calls:

- `company_id`: pass as `companyId`.
- `menu_type`: numeric meal type, pass as `mt` or `menuType`.
- `list_data.menu_type`: display label, such as lunch or dinner.
- `list_data.status`: `1` already ordered, `2` open, `3` closed.
- `list_data.menu_end_time`: order cutoff.
- `list_data.menu`: ordered dishes when status is already ordered.
- `list_data.menu_num`: ordered quantity.

Do not hardcode company ids. Always derive them from `companyIndex/` for the selected date.

## Menu Discovery

```http
GET /businessIndex/?api_token=<token>&menu_date=<YYYY-MM-DD>&mt=<menuType>&companyId=<companyId>
```

Returns restaurants for the selected slot. Ignore the synthetic "all restaurants" row when it appears.

```http
GET /getCookbook/?api_token=<token>&busid=<businessId>&menu_date=<YYYY-MM-DD>&mt=<menuType>&companyId=<companyId>
```

Cookbook items include:

- `id`: cookbook entry id for `cart/add/`.
- `menu_id`: menu id for `cart/add/`.
- `is_sellout`: non-zero means unavailable.
- `cookbook.menu_name`: user-facing dish name.
- `cookbook.image`: image path.

## Cart

```http
GET /cart/emptyCart/?api_token=<token>&menuType=<menuType>&reserveDate=<YYYY-MM-DD>&companyId=<companyId>
```

Clears the cart for the selected meal slot. Use only for the target slot.

```http
POST /cart/add/?api_token=<token>&companyId=<companyId>
Content-Type: application/x-www-form-urlencoded
```

Body:

```text
id=<cookbookEntryId>&num=1&menu_id=<menuId>&mt=<menuType>&reserve_date=<YYYY-MM-DD>
```

Verify with:

```http
GET /lists/?api_token=<token>&menuType=<menuType>&reserveDate=<YYYY-MM-DD>&companyId=<companyId>
GET /cart/total/?api_token=<token>&menuType=<menuType>&reserveDate=<YYYY-MM-DD>&companyId=<companyId>
```

`cart/total/` may hide amounts as `***`. `company_meal_type = 1` has been observed for fully company-covered meals.

## Checkout

```http
GET /userAddress/?api_token=<token>&reserveDate=<YYYY-MM-DD>&companyId=<companyId>
```

Use the selected/default `id` as `address_id`.

```http
POST /order/add/?api_token=<token>&menuType=<menuType>&reserveDate=<YYYY-MM-DD>&companyId=<companyId>
Content-Type: application/x-www-form-urlencoded
```

Body:

```text
isTableware=<0-or-1>&tablewareStatus=<1-or-2>&address_id=<addressId>&is_balance_pay=<0-or-1>
```

Tableware:

- `tablewareStatus=1`: needs tableware.
- `tablewareStatus=2`: no tableware.
- `isTableware=1` only when requesting tableware.

Success includes `data.orderNumber` and `data.isWechatPay`. If `isWechatPay` indicates payment is required, stop unless the user explicitly asked to continue through payment.

## Verification

After submission, call `companyIndex/` again for the date:

- target slot should be `status = 1`;
- `list_data.menu` should include the expected `menu_name`;
- `list_data.menu_num` should match expected quantity.

## Recommended Flow

1. Login.
2. Discover slots with `companyIndex/`.
3. Skip already ordered or closed slots unless the user explicitly requests a change.
4. Fetch restaurants and cookbook items.
5. Match exact dish keywords; ask on ambiguity.
6. Clear the target slot cart only.
7. Add exactly one chosen item unless the user requested a different quantity.
8. Verify cart contents and payment mode.
9. Submit order.
10. Verify order status from `companyIndex/`.
