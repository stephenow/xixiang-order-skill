param(
  [ValidateSet('List', 'Order')]
  [string]$Action = 'List',

  [string]$StartDate,
  [int]$Days = 5,

  [string]$Date,
  [string]$Meal,
  [string]$Keyword,

  [string]$CredentialsPath = '.xixiang-credentials.json',
  [switch]$NeedTableware
)

$ErrorActionPreference = 'Stop'
$BaseUrl = 'https://api.platform.xixiang000.com/'
$Headers = @{
  Accept = 'application/json, text/plain, */*'
  Origin = 'https://wechat.platform.xixiang000.com'
  Referer = 'https://wechat.platform.xixiang000.com/'
  'User-Agent' = 'Mozilla/5.0'
}

function Write-Json($value) {
  $value | ConvertTo-Json -Depth 32
}

function Read-LocalCredentials {
  if (-not (Test-Path -LiteralPath $CredentialsPath)) {
    throw "Missing credentials file: $CredentialsPath. Copy .xixiang-credentials.example.json to .xixiang-credentials.json and fill it locally."
  }

  $credentials = Get-Content -Raw -LiteralPath $CredentialsPath | ConvertFrom-Json
  if (-not $credentials.phone -or -not $credentials.password) {
    throw "Credentials file must contain phone and password fields."
  }
  return $credentials
}

function Invoke-XxGet([string]$Path) {
  Invoke-RestMethod -Method Get -Uri ($BaseUrl + $Path) -Headers $Headers
}

function Invoke-XxPost([string]$Path, $Body) {
  Invoke-RestMethod -Method Post -Uri ($BaseUrl + $Path) -Headers $Headers -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -Body $Body
}

function Login-Xixiang {
  $credentials = Read-LocalCredentials
  $login = Invoke-XxPost 'login/' @{
    phone = $credentials.phone
    password = $credentials.password
    qrcodeValue = ''
    openid = ''
  }

  if ([int]$login.code -ne 1 -or -not $login.data.api_token) {
    throw "Login failed: $($login.message)"
  }

  return $login.data.api_token
}

function Escape-Api([string]$Value) {
  [uri]::EscapeDataString($Value)
}

function Get-MealCode([string]$MealName) {
  $value = ''
  if ($null -ne $MealName) {
    $value = $MealName.Trim().ToLowerInvariant()
  }

  $breakfast = [string]([char]0x65E9) + [string]([char]0x9910)
  $lunch = [string]([char]0x5348) + [string]([char]0x9910)
  $mall = [string]([char]0x5546) + [string]([char]0x57CE)
  $dinner = [string]([char]0x665A) + [string]([char]0x9910)

  if ($value -eq '1' -or $value -eq 'breakfast' -or $value -eq $breakfast) { return 1 }
  if ($value -eq '2' -or $value -eq 'lunch' -or $value -eq $lunch) { return 2 }
  if ($value -eq '3' -or $value -eq 'mall' -or $value -eq $mall) { return 3 }
  if ($value -eq '4' -or $value -eq 'dinner' -or $value -eq $dinner) { return 4 }

  throw "Unknown meal value: $MealName. Use 1/2/4, breakfast/lunch/dinner, or Chinese meal labels."
}

function Get-StatusText($Status) {
  switch ([string]$Status) {
    '1' { return 'already_ordered' }
    '2' { return 'open' }
    '3' { return 'closed' }
    default { return [string]$Status }
  }
}

function Get-FlatCartRows($CartData) {
  $rows = @()
  if ($null -eq $CartData) { return $rows }
  foreach ($property in $CartData.PSObject.Properties) {
    foreach ($row in @($property.Value)) {
      $rows += $row
    }
  }
  return $rows
}

function Get-Slot($Token, [string]$TargetDate, [int]$MealCode) {
  $companyIndex = Invoke-XxGet "companyIndex/?api_token=$(Escape-Api $Token)&menu_date=$TargetDate"
  return @($companyIndex.data | Where-Object { [int]$_.menu_type -eq $MealCode } | Select-Object -First 1)[0]
}

function Get-MenuForSlot($Token, [string]$TargetDate, $Slot) {
  $companyId = $Slot.company_id
  $mealCode = $Slot.menu_type
  $businessIndex = Invoke-XxGet "businessIndex/?api_token=$(Escape-Api $Token)&menu_date=$TargetDate&mt=$mealCode&companyId=$companyId"
  $restaurants = @()

  foreach ($business in @($businessIndex.data | Where-Object { $_.business_id -ne -1 })) {
    $cookbook = Invoke-XxGet "getCookbook/?api_token=$(Escape-Api $Token)&busid=$($business.business_id)&menu_date=$TargetDate&mt=$mealCode&companyId=$companyId"
    $items = @()
    foreach ($group in @($cookbook.data)) {
      foreach ($item in @($group)) {
        $items += [pscustomobject]@{
          name = $item.cookbook.menu_name
          id = $item.id
          menuId = $item.menu_id
          soldOut = ([int]$item.is_sellout -ne 0)
        }
      }
    }

    $restaurants += [pscustomobject]@{
      name = $business.business_name
      businessId = $business.business_id
      items = $items
    }
  }

  return $restaurants
}

function Invoke-ListMenus {
  $token = Login-Xixiang
  if (-not $StartDate) {
    $StartDate = (Get-Date).ToString('yyyy-MM-dd')
  }

  $start = [datetime]::ParseExact($StartDate, 'yyyy-MM-dd', $null)
  $daysOut = @()

  for ($i = 0; $i -lt $Days; $i += 1) {
    $targetDate = $start.AddDays($i).ToString('yyyy-MM-dd')
    $companyIndex = Invoke-XxGet "companyIndex/?api_token=$(Escape-Api $token)&menu_date=$targetDate"
    $slots = @()

    foreach ($slot in @($companyIndex.data)) {
      $slotOut = [ordered]@{
        meal = $slot.list_data.menu_type
        status = Get-StatusText $slot.list_data.status
        cutoff = $slot.list_data.menu_end_time
        ordered = $slot.list_data.menu
        restaurants = @()
      }

      if ([string]$slot.list_data.status -eq '2') {
        $slotOut.restaurants = Get-MenuForSlot $token $targetDate $slot
      }

      $slots += [pscustomobject]$slotOut
    }

    $daysOut += [pscustomobject]@{
      date = $targetDate
      slots = $slots
    }
  }

  Write-Json ([pscustomobject]@{ ok = $true; days = $daysOut })
}

function Invoke-OrderMeal {
  if (-not $Date -or -not $Meal -or -not $Keyword) {
    throw 'Order action requires -Date, -Meal, and -Keyword.'
  }

  $token = Login-Xixiang
  $mealCode = Get-MealCode $Meal
  $slot = Get-Slot $token $Date $mealCode
  if (-not $slot) { throw "No slot found for $Date $Meal." }

  $status = [string]$slot.list_data.status
  if ($status -eq '1') {
    Write-Json ([pscustomobject]@{
      ok = $true
      skipped = $true
      message = 'Slot is already ordered.'
      ordered = $slot.list_data.menu
    })
    return
  }
  if ($status -ne '2') {
    throw "Slot is not open. Status: $(Get-StatusText $slot.list_data.status)."
  }

  $restaurants = Get-MenuForSlot $token $Date $slot
  $matches = @()
  foreach ($restaurant in $restaurants) {
    foreach ($item in @($restaurant.items | Where-Object { $_.name -like "*$Keyword*" })) {
      $matches += [pscustomobject]@{
        restaurant = $restaurant.name
        businessId = $restaurant.businessId
        item = $item
      }
    }
  }

  if ($matches.Count -eq 0) { throw "No dish matched keyword: $Keyword." }
  if ($matches.Count -gt 1) {
    Write-Json ([pscustomobject]@{ ok = $false; message = 'Keyword is ambiguous.'; matches = $matches })
    return
  }

  $match = $matches[0]
  if ($match.item.soldOut) { throw "Dish is sold out: $($match.item.name)." }

  $companyId = $slot.company_id
  $null = Invoke-XxGet "cart/emptyCart/?api_token=$(Escape-Api $token)&menuType=$mealCode&reserveDate=$Date&companyId=$companyId"
  $add = Invoke-XxPost "cart/add/?api_token=$(Escape-Api $token)&companyId=$companyId" @{
    id = $match.item.id
    num = 1
    menu_id = $match.item.menuId
    mt = $mealCode
    reserve_date = $Date
  }
  if ([int]$add.code -ne 1) { throw "Cart add failed: $($add.message)" }

  $cart = Invoke-XxGet "lists/?api_token=$(Escape-Api $token)&menuType=$mealCode&reserveDate=$Date&companyId=$companyId"
  $rows = @(Get-FlatCartRows $cart.data)
  if ($rows.Count -ne 1 -or [int]$rows[0].num -ne 1 -or $rows[0].menu_id -ne $match.item.menuId) {
    throw 'Cart verification failed.'
  }

  $total = Invoke-XxGet "cart/total/?api_token=$(Escape-Api $token)&menuType=$mealCode&reserveDate=$Date&companyId=$companyId"
  if ([int]$total.data.company_meal_type -ne 1) {
    throw "Unexpected payment mode. company_meal_type=$($total.data.company_meal_type), should_pay_price=$($total.data.should_pay_price)"
  }

  $address = Invoke-XxGet "userAddress/?api_token=$(Escape-Api $token)&reserveDate=$Date&companyId=$companyId"
  $addressId = @($address.data | Select-Object -First 1).id
  if (-not $addressId) { throw 'No address is available.' }

  $tablewareStatus = 2
  $isTableware = 0
  if ($NeedTableware) {
    $tablewareStatus = 1
    $isTableware = 1
  }

  $submit = Invoke-XxPost "order/add/?api_token=$(Escape-Api $token)&menuType=$mealCode&reserveDate=$Date&companyId=$companyId" @{
    isTableware = $isTableware
    tablewareStatus = $tablewareStatus
    address_id = $addressId
    is_balance_pay = 0
  }
  if ([int]$submit.code -ne 1) { throw "Order submit failed: $($submit.message)" }

  $verifiedSlot = Get-Slot $token $Date $mealCode
  Write-Json ([pscustomobject]@{
    ok = $true
    date = $Date
    meal = $Meal
    restaurant = $match.restaurant
    item = $match.item.name
    orderNumber = $submit.data.orderNumber
    isWechatPay = $submit.data.isWechatPay
    verifyStatus = Get-StatusText $verifiedSlot.list_data.status
    verifyMenu = $verifiedSlot.list_data.menu
  })
}

if ($Action -eq 'List') {
  Invoke-ListMenus
} else {
  Invoke-OrderMeal
}
