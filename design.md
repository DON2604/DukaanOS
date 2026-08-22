# DukaanOS --- Complete UI/UX Design Specification

## 1. Product Overview

**DukaanOS** is a smartphone-first, zero-entry ERP for small businesses
such as kirana stores, bakeries, vegetable shops, hardware stores,
clothing shops, and other neighborhood merchants.

The core product principle is:

> **The phone observes the shop, AI understands the activity, and the
> ERP updates itself.**

Traditional ERP:

``` text
Shopkeeper
   ↓
Manual data entry
   ↓
ERP
   ↓
Reports
```

DukaanOS:

``` text
Real shop activity
        ↓
Camera + Microphone + Phone Sensors
        ↓
On-device AI
        ↓
Understand / Observe / Predict
        ↓
Automatic ERP updates
        ↓
Business insights + actions
```

The product should not feel like an AI demo. It should feel like an
excellent, trustworthy business application in which intelligence is
embedded into the workflows.

The design must make the core promise visible through behavior:

-   Camera sees.
-   Microphone listens.
-   Sensors understand movement.
-   AI understands business activity.
-   ERP updates itself.
-   The shopkeeper reviews, approves, or acts.

------------------------------------------------------------------------

# 2. Design Goals

## Primary goals

1.  Make the application understandable to a non-technical shopkeeper
    within seconds.
2.  Minimize typing and manual data entry.
3.  Make camera-based workflows first-class.
4.  Make voice interaction practical rather than gimmicky.
5.  Make inventory discrepancies visible and actionable.
6.  Make important business decisions easier.
7.  Make the application trustworthy enough to handle money, stock, and
    customer credit.
8.  Make offline operation feel normal rather than like an error state.
9.  Keep interactions optimized for one-handed smartphone use.
10. Make the application feel modern without looking like generic
    AI-generated UI.

## Secondary goals

-   Support natural Indian business language.
-   Surface only useful business information.
-   Make complex ERP concepts understandable without ERP terminology.
-   Reduce training requirements.
-   Make every important workflow shorter than its traditional ERP
    equivalent.

------------------------------------------------------------------------

# 3. Product Positioning

Do not position the product as:

> AI billing app

> AI POS

> Another ERP for kirana stores

> ChatGPT for shopkeepers

The stronger positioning is:

> **The zero-entry ERP for every small shop.**

And the central product statement is:

> **We are not teaching small shopkeepers how to operate an ERP. We are
> teaching the smartphone how to understand the shop and maintain the
> ERP automatically.**

The UI should reinforce this positioning.

------------------------------------------------------------------------

# 4. Target User

Primary user:

-   Small shop owner
-   Frequently busy
-   Often operates the shop personally
-   May not use desktop software
-   May already rely on memory, notebooks, calculators, WhatsApp, and
    informal processes
-   Needs fast interactions
-   May be more comfortable speaking than typing
-   Needs confidence that stock and money records are correct

The interface must therefore avoid assuming:

-   ERP knowledge
-   accounting terminology
-   SKU knowledge
-   advanced technical knowledge
-   willingness to configure complex software

------------------------------------------------------------------------

# 5. Design Personality

DukaanOS should feel:

-   Practical
-   Trustworthy
-   Calm
-   Modern
-   Fast
-   Human
-   Financially credible
-   Indian
-   Tactile
-   Efficient
-   Quietly intelligent

It should **not** feel:

-   Futuristic for the sake of being futuristic
-   Like an AI chatbot
-   Like a banking app clone
-   Like a generic SaaS dashboard
-   Like a corporate ERP
-   Like a hackathon mockup
-   Overly colorful
-   Overly rounded
-   Glassmorphic
-   Filled with gradients
-   Filled with floating cards
-   Filled with decorative AI elements

------------------------------------------------------------------------

# 6. Anti-AI-Slop Rules

Never use:

-   Robot illustrations
-   Glowing brains
-   Neural-network graphics
-   Purple/blue AI gradients
-   Giant gradient text
-   Sparkles around every AI action
-   Generic AI avatars
-   Floating glass cards everywhere
-   Excessive pill-shaped controls
-   Excessive rounded containers
-   Decorative 3D objects
-   Random futuristic backgrounds
-   Unnecessary charts
-   "AI-powered" badges everywhere
-   Large empty hero areas that waste mobile space

The application should not visually announce:

> "LOOK! THIS IS AI!"

Instead, the user should discover the intelligence through the product's
behavior.

For example:

Bad:

> ✨ AI POWERED INVENTORY INTELLIGENCE ✨

Good:

> **Coke is selling faster than usual. You may run out tomorrow.**

------------------------------------------------------------------------

# 7. Visual Design Direction

## 7.1 Theme

Primary theme: **light mode**

Background:

-   Warm off-white / very light neutral
-   Avoid pure white everywhere
-   Use subtle tonal separation between application background and
    content surfaces

Text:

-   Dark charcoal
-   Near-black for important figures
-   Medium gray for secondary information
-   Light gray only for tertiary information

Semantic colors:

-   Green → positive / completed / healthy
-   Amber → attention / warning
-   Red → critical issue
-   Neutral → informational

Colors should communicate state, not decorate the interface.

------------------------------------------------------------------------

# 8. Suggested Color Tokens

These are starting design tokens and can be tuned during implementation.

``` text
Background
----------------
bg-primary       #F7F7F3
bg-surface       #FFFFFF
bg-subtle        #F1F1EC

Text
----------------
text-primary     #171917
text-secondary   #60645F
text-tertiary    #8A8E88
text-disabled    #B4B7B2

Border
----------------
border-default   #E2E4DE
border-strong    #CDD0C8

Semantic
----------------
success          #247A4A
success-soft     #E8F4EC

warning          #A76A00
warning-soft     #FFF3D6

danger           #B83A3A
danger-soft      #FCEAEA

Information
----------------
info              #356B9A
info-soft         #EAF2F8

Primary Action
----------------
primary           #1F6F46
primary-pressed   #185A39
```

Do not introduce additional colors unless there is a semantic reason.

------------------------------------------------------------------------

# 9. Typography

Use a highly legible modern sans-serif.

Recommended characteristics:

-   High x-height
-   Excellent number readability
-   Clear Hindi/Latin compatibility if multilingual support is
    introduced
-   Strong weight hierarchy
-   Avoid overly geometric display fonts

Suggested hierarchy:

``` text
Display / KPI       32–40 px / Bold
Page title          24–28 px / Semibold
Section title       18–20 px / Semibold
Body                15–17 px / Regular
Button              15–16 px / Semibold
Secondary           13–14 px / Regular
Metadata            12–13 px / Medium
```

Do not make body text tiny.

The shopkeeper should be able to glance at the screen while standing at
a counter.

------------------------------------------------------------------------

# 10. Spacing System

Use a consistent 4/8-based spacing system.

``` text
4 px   micro spacing
8 px   compact spacing
12 px  row spacing
16 px  standard padding
20 px  section spacing
24 px  major section spacing
32 px  screen-level separation
40 px  major visual separation
```

Mobile screens should generally use:

``` text
Horizontal page padding: 16–20 px
```

Avoid excessive whitespace that makes the application feel like a
marketing website.

------------------------------------------------------------------------

# 11. Corner Radius

Use moderate corner radii.

Suggested:

``` text
Small controls      8 px
Inputs              10 px
Cards               12–14 px
Bottom sheets       20 px
Large modal         20 px
```

Avoid turning every component into a pill.

Pills should be reserved for:

-   Status
-   Filters
-   Compact categories
-   Temporary states

------------------------------------------------------------------------

# 12. Elevation and Borders

Prefer borders and tonal separation over heavy shadows.

Default:

``` text
1 px subtle border
Minimal shadow
```

Use stronger elevation only for:

-   Floating action controls
-   Bottom sheets
-   Dialogs
-   Camera overlays
-   Temporary confirmation surfaces

The product should feel grounded and physical.

------------------------------------------------------------------------

# 13. Iconography

Use a consistent outlined/duotone icon system.

Icons must communicate function quickly.

Core icons:

``` text
Home
Sales
Inventory
Khata
More
Camera
Microphone
Search
Barcode
Receipt
Package
Alert
Check
Arrow
Calendar
Customer
Supplier
Wallet
Trend
Settings
```

Avoid decorative AI icons.

The microphone icon is enough to communicate voice.

The camera icon is enough to communicate scanning.

------------------------------------------------------------------------

# 14. Navigation

Use a simple bottom navigation.

``` text
┌──────────────────────────────────────┐
│                                      │
│              SCREEN                  │
│                                      │
│                                      │
├──────────────────────────────────────┤
│ Home │ Sales │ Inventory │ Khata │ More │
└──────────────────────────────────────┘
```

Primary navigation:

1.  Home
2.  Sales
3.  Inventory
4.  Khata
5.  More

The navigation should remain consistent across the core application.

Camera-based actions should not require navigating through multiple
menus.

------------------------------------------------------------------------

# 15. Core Global Actions

The most important operations should be easy to access:

``` text
+ New Sale
Scan Bill
Stock Audit
Ask Dukaan
```

These actions can appear on Home and in relevant contexts.

The camera should feel like a core business input.

------------------------------------------------------------------------

# 16. Home Dashboard

## Purpose

The home screen is a **business command center**, not a conventional
analytics dashboard.

The user should answer these questions immediately:

1.  How much did I sell?
2.  How much did I make?
3.  What needs attention?
4.  What should I do next?

## Layout

``` text
Good morning, Ramesh
Here's what needs your attention today.

₹14,820
Today's sales
↑ 12% vs yesterday

Profit
₹2,940

NEEDS YOUR ATTENTION

6 products are low on stock
3 products expire soon
2 inventory mismatches
₹4,820 customer credit outstanding

QUICK ACTIONS

[ New Sale ]
[ Scan Bill ]
[ Stock Audit ]
[ Ask Dukaan ]

TODAY'S QUICK UPDATE

Coke is selling faster than usual.
You have 6 bottles left and may run out tomorrow.

[ View recommendation ]

RECENT ACTIVITY

10:42 AM
Supplier invoice added
+48 Maggi · +24 Coke

10:18 AM
Sale
₹486

9:55 AM
Credit added
Rajesh · ₹340
```

## Rules

Do not use:

-   Large chart walls
-   8--12 KPI cards
-   Decorative graphs
-   Dense tables

Use action-oriented rows.

------------------------------------------------------------------------

# 17. Onboarding

## Screen 1 --- Welcome

Headline:

> Your shop. Your phone. That's enough.

Subtext:

> DukaanOS keeps track of stock, sales and customers without making you
> do the data entry.

CTA:

> Set up my shop

Secondary:

> See how it works

Keep this screen extremely clean.

------------------------------------------------------------------------

# 18. Shop Profile

Title:

> Tell us about your shop

Fields:

-   Shop name
-   Owner name
-   Business type

Business types:

-   Kirana
-   Bakery
-   Vegetable shop
-   Hardware
-   Clothing
-   Other

Do not ask for unnecessary information during onboarding.

------------------------------------------------------------------------

# 19. Scan My Shop

This is one of the first major "wow" moments.

Title:

> Show us your shop

Instruction:

> Move your phone slowly across your shelves. We'll create your starting
> inventory.

Camera preview:

``` text
┌─────────────────────────────┐
│                             │
│       LIVE CAMERA           │
│                             │
│  Maggi   Oreo   Coke        │
│   14      6      8          │
│                             │
│        Move slowly →        │
│                             │
│ Shelf 3 of 6                │
└─────────────────────────────┘
```

Detected labels should be subtle.

Do not clutter the camera preview.

------------------------------------------------------------------------

# 20. Inventory Created

After the initial scan:

``` text
Your inventory is ready

142 products detected
₹74,420 estimated stock value
8 shelves scanned

Maggi Masala 70g     14
Parle-G ₹10          22
Coca-Cola 750ml       6
Tata Salt 1kg         7

[ Go to my shop ]
```

The magic should come from the result, not animation.

------------------------------------------------------------------------

# 21. New Sale

## Goal

A shopkeeper should be able to create a sale in seconds.

Header:

> New Sale

Modes:

``` text
Barcode
AI Basket
```

## Barcode mode

Camera opens.

Detection:

``` text
Coca-Cola 750ml
₹40

[ + Add ]
```

After multiple scans:

``` text
4 items
₹98

[ Generate bill ]
```

## AI Basket mode

Instruction:

> Point at the basket

Subtext:

> Keep the products visible. We'll identify them.

Detected:

``` text
Maggi Masala ×2
Coca-Cola ×1
Oreo ×1
Surf Excel ×1
```

Bottom:

``` text
4 items
₹98

[ Generate bill ]
```

After checkout:

``` text
Sale complete ✓

₹98
4 items

Inventory updated
Customer: Walk-in

[ New sale ]
[ View today's sales ]
```

------------------------------------------------------------------------

# 22. Supplier Invoice Scanner

## Screen 1

Title:

> Scan supplier bill

Subtext:

> Take a photo. We'll add the stock for you.

Camera:

-   Invoice guide
-   Large capture button
-   Minimal controls

CTA:

> Take photo

## Screen 2

Processing:

> Reading your bill...

Avoid generic loading graphics.

## Screen 3

Review:

``` text
Bill detected

ABC Distributors

Maggi Masala 70g
48 × ₹12
+48 stock

Tata Salt 1kg
20 × ₹22
+20 stock

Parle-G 100g
50 × ₹8
+50 stock

Coca-Cola 750ml
24 × ₹34
+24 stock

Total
₹2,814

[ Add to inventory ]
```

If OCR confidence is low, show:

> Check 1 item

Allow editing directly.

## Screen 4

``` text
Inventory updated

+142 units
₹2,814 purchase recorded

[ Done ]
```

------------------------------------------------------------------------

# 23. AI Stock Audit

This is the flagship feature.

## Entry screen

Title:

> Check your actual stock

Subtext:

> Walk through the shop slowly. We'll compare what we see with your
> inventory.

Explain:

``` text
Camera
Counts products

Motion sensors
Track shelf coverage

AI
Finds mismatches
```

CTA:

> Start stock audit

------------------------------------------------------------------------

# 24. Live Shelf Sweep

Full-screen camera.

Overlay:

``` text
STOCK AUDIT
Shelf 2 of 6

Maggi ×12 ✓
Oreo ×6 ✓
Pepsi ×8 ✓

Shelf coverage
████████████░░ 76%

Move slowly →
```

The UI should be minimal.

The camera feed is the primary visual.

------------------------------------------------------------------------

# 25. Stock Audit Result

``` text
Stock check complete

142 products checked
8 mismatches
13 low-stock items
4 expiry risks
```

Comparison:

``` text
Product       ERP     Seen     Difference

Maggi          18      11        −7
Coke           12      12         ✓
Parle-G        24      22        −2
Oreo            9       4        −5
```

Use red only for meaningful critical states.

------------------------------------------------------------------------

# 26. Mismatch Detail

Title:

> Maggi stock mismatch

``` text
Expected stock
18

Detected stock
11

Difference
−7
```

Possible reasons:

-   Missed sale
-   Damaged stock
-   Wrong purchase quantity
-   Product misplaced

Actions:

``` text
[ Review stock ]
[ Ignore for now ]
```

Never imply theft unless independently established.

Use neutral language such as:

> Inventory mismatch

or

> Inventory movement cannot be explained by recorded transactions.

------------------------------------------------------------------------

# 27. Ask Dukaan

This is the conversational ERP interface.

Header:

> Ask Dukaan

Subtext:

> Ask about your shop or tell me what to do.

Suggested prompts:

``` text
Maggi kitna bacha hai?
Aaj kitna sale hua?
Ramesh ka udhaar?
Kal kya order karna hai?
```

Microphone:

-   Large
-   Easy to press
-   No glowing orb
-   No AI avatar

Listening state:

> Listening...

Use a subtle waveform.

------------------------------------------------------------------------

# 28. Business Question Example

User:

> Kal kya order karna hai?

Response:

``` text
Based on your recent sales, I'd order:

Coca-Cola
24 bottles

Maggi
30 packets

Parle-G
20 packets

Coke is selling faster than usual
and may run out tomorrow.

[ Review order ]
[ Send to supplier ]
```

The recommendation should be the visual focus, not the conversation.

------------------------------------------------------------------------

# 29. ERP Action Through Voice

User:

> Ramesh ke naam 500 udhaar likh do.

Instead of immediately mutating financial data, show:

``` text
Ramesh Kumar

Current due
₹620

Add credit
₹500

New due
₹1,120

[ Confirm ]
```

Important financial mutations should require confirmation.

------------------------------------------------------------------------

# 30. Inventory

## Purpose

The inventory screen is a practical stock ledger.

Header:

> Inventory

Search:

> Search products

Filters:

``` text
All
Low stock
Expiring
Mismatch
```

Summary:

``` text
142 products
₹74,420 stock value
```

Product rows:

``` text
Maggi Masala 70g
Stock 14
Selling ₹14
Cost ₹11.20

Coca-Cola 750ml
Stock 6
Selling ₹40
Cost ₹34
Low stock

Amul Milk 500ml
Stock 12
Expires in 2 days
```

Avoid giant product cards.

------------------------------------------------------------------------

# 31. Product Detail

Example:

``` text
Maggi Masala 70g

Current stock
14

Selling price
₹14

Purchase price
₹11.20

Profit
₹2.80 / unit

Recent movement

+48 purchase
−12 sales
−2 adjustment
```

AI recommendation:

> At your current sales rate, you may run out in 2 days.

CTA:

> Create purchase order

------------------------------------------------------------------------

# 32. Digital Khata

Khata should feel familiar.

Header:

> Khata

Summary:

``` text
₹4,820
Total outstanding

12 customers
```

Search:

> Search customer

Customer list:

``` text
Ramesh Kumar
₹1,120 due

Rajesh
₹960 due

Amit
₹340 due
```

------------------------------------------------------------------------

# 33. Customer Detail

``` text
Ramesh Kumar

Total due
₹1,120

Today
Credit +₹500
Udhaar

Yesterday
Purchase ₹340

12 Aug
Payment −₹620
```

Actions:

``` text
[ Add transaction ]
[ Record payment ]
```

Voice shortcut:

> Say: "Ramesh ko ₹500 udhaar"

------------------------------------------------------------------------

# 34. Business Intelligence

Title:

> Your shop

Subtitle:

> Simple answers to important questions.

## Today

``` text
Sales
₹18,450

Estimated profit
₹3,210

Transactions
93

Credit given
₹1,240
```

## What should I do?

Prioritized recommendations:

``` text
ORDER SOON
Coca-Cola
24 recommended
Likely to run out tomorrow.

SELL FIRST
Amul Milk
8 units
Expires in 2 days.

CHECK STOCK
Maggi
7-unit mismatch
Physical stock is lower than recorded stock.
```

## Trend

Use one or two simple charts.

Example:

``` text
Sales this week

Mon ₹12k
Tue ₹14k
Wed ₹13k
Thu ₹15k
Fri ₹18k
```

Do not build a financial analytics wall.

------------------------------------------------------------------------

# 35. Expiry Management

Title:

> Sell first

Subtitle:

> Products that may expire before you sell them.

Example:

``` text
Amul Milk
12 units
Expires in 2 days

Bread
8 units
Expires in 3 days

Curd
6 units
Expires in 4 days
```

Recommendation:

> 12 milk packets may not sell before expiry.

Actions:

``` text
[ View product ]
[ Create discount ]
```

Product analysis:

``` text
Current stock
20

Expected sales before expiry
7

Potential excess
13

Recommendation
Consider a 10–15% discount.
```

------------------------------------------------------------------------

# 36. Supplier Ordering

Recommended purchase:

``` text
RECOMMENDED PURCHASE

ABC Distributor

Maggi 70g
48

Coca-Cola 750ml
24

Parle-G ₹10
50

Oreo ₹20
20

[ Send order ]
```

The order can later generate a WhatsApp-friendly supplier message.

------------------------------------------------------------------------

# 37. Sales History

Sales screen should prioritize:

-   Today's sales
-   Number of transactions
-   Average transaction
-   Recent transactions

Example:

``` text
Today's sales
₹18,450

93 transactions

10:42 AM
₹486
4 items

10:18 AM
₹240
2 items

9:55 AM
₹340
Credit · Rajesh
```

Avoid excessive filtering unless required.

------------------------------------------------------------------------

# 38. More / Settings

Keep this screen functional.

``` text
MORE

BUSINESS
Business profile
Suppliers
Products
Price settings

TOOLS
Reports
Expiry
Stock adjustments
Data backup

PREFERENCES
Language
Voice settings
Notifications
Offline data

ABOUT
DukaanOS
Privacy
Help
```

Offline state:

``` text
Offline — data saved on this phone
```

or:

``` text
Offline data synced ✓
```

------------------------------------------------------------------------

# 39. Offline UX

Offline operation is a product principle, not merely a technical
feature.

Do not show alarming:

> ERROR: NO INTERNET

Instead:

``` text
Offline
Your shop continues to work normally.
```

For locally saved actions:

``` text
Saved on this phone
Will sync when connected
```

Important local operations should continue whenever technically
possible.

------------------------------------------------------------------------

# 40. AI Interaction Principles

AI should be:

### Contextual

It should know the current shop state.

### Actionable

It should recommend or perform useful actions.

### Explainable

Recommendations should include a concise reason.

### Confirmable

Financially important mutations should be confirmed.

### Quiet

Do not interrupt the user unnecessarily.

### Natural

Use the shopkeeper's language.

Examples:

``` text
Maggi kitna bacha hai?
Aaj kitna bikri hua?
Ramesh ka udhaar batao.
Kal kya order karna hai?
Pepsi ke 24 bottle aaye hain.
Doodh almost khatam ho gaya.
```

------------------------------------------------------------------------

# 41. Language

The application should eventually support:

-   English
-   Hindi
-   Hinglish
-   Regional languages

But language support should not make the UI cluttered.

Prefer short phrases.

Instead of:

> Inventory Reconciliation Exception Detected

Use:

> Stock mismatch detected

Instead of:

> Accounts Receivable Outstanding Balance

Use:

> Customer credit

Instead of:

> Purchase Order Recommendation

Use:

> What to order

------------------------------------------------------------------------

# 42. Notification Language

Use human, action-oriented notifications.

Good:

> Coke may run out tomorrow.

Good:

> 8 milk packets expire in 2 days.

Good:

> Physical Maggi stock is 7 units lower than your records.

Bad:

> AI detected a critical inventory anomaly.

Bad:

> Intelligent inventory alert activated.

------------------------------------------------------------------------

# 43. Empty States

Empty states should teach the user what to do.

Inventory empty:

``` text
No products yet

Scan your shelves or add a supplier bill
to create your inventory.

[ Scan shop ]
[ Scan bill ]
```

Khata empty:

``` text
No credit records

Customers with credit will appear here.
```

Sales empty:

``` text
No sales yet today

Start a new sale when your first customer arrives.

[ New sale ]
```

------------------------------------------------------------------------

# 44. Error States

Errors should be understandable and recoverable.

Bad:

> OCR_ERROR_402

Good:

> We couldn't read 1 item clearly.

Action:

> Review item

Camera issue:

> Camera access is needed to scan products.

Action:

> Allow camera

Offline:

> You're offline. This action will be saved locally.

------------------------------------------------------------------------

# 45. Confirmation Patterns

Use confirmation when:

-   Changing stock manually
-   Adding customer credit
-   Recording payment
-   Approving purchase quantities
-   Applying discounts
-   Deleting records

Avoid confirmation for:

-   Opening screens
-   Reading information
-   Scanning
-   Non-destructive navigation

------------------------------------------------------------------------

# 46. Camera UX Rules

Camera screens should be visually minimal.

Priorities:

1.  Camera feed
2.  Detection result
3.  One instruction
4.  One primary action

Do not cover the camera with UI.

Use overlays only when they help the task.

------------------------------------------------------------------------

# 47. Motion Sensor UX

Gyroscope and accelerometer should be invisible most of the time.

The user does not need to know sensor data.

The product simply says:

> Move slowly →

The system internally uses motion data to:

-   Understand scanning direction
-   Track shelf coverage
-   Reduce repeated scanning
-   Structure inventory sweeps

Do not expose technical sensor terminology in normal UX.

------------------------------------------------------------------------

# 48. Data Visualization

Charts should answer questions.

Good:

> Are sales increasing?

Good:

> Which products make the most profit?

Good:

> Is today's revenue unusually low?

Avoid charts simply because the screen looks empty.

Prefer:

-   Simple line chart
-   Simple bar chart
-   Comparison numbers
-   Trend indicators

Avoid:

-   Pie-chart overload
-   Multiple axes
-   Dense legends
-   Decorative graphs

------------------------------------------------------------------------

# 49. Product Recognition UI

When products are detected, use small labels anchored near the object.

Example:

``` text
[Maggi]
  ×12
```

Confidence should only be exposed when user verification is required.

For ambiguous recognition:

``` text
Looks like:
Maggi Masala 70g

[ Confirm ]
[ Change ]
```

Do not show raw machine-learning confidence percentages unless
necessary.

------------------------------------------------------------------------

# 50. Business Trust

The UI handles:

-   Money
-   Inventory
-   Customer credit
-   Supplier purchases
-   Business performance

Therefore:

-   Avoid playful UI for financial mutations.
-   Avoid misleading certainty.
-   Explain recommendations.
-   Show when information is estimated.
-   Make corrections easy.
-   Keep transaction history visible.

Use terms such as:

> Estimated profit

when the underlying calculation is not finalized.

------------------------------------------------------------------------

# 51. Dashboard Information Hierarchy

Every screen should follow:

``` text
1. What is happening?
2. Why does it matter?
3. What should I do?
```

Example:

``` text
Coke stock is low.

6 bottles remain.
Recent sales are 8/day.

[ Order 24 ]
```

This is better than:

``` text
Coke
Stock: 6
Velocity: 8/day
Forecast: 0.75 days
Safety stock: 5
Reorder point: 13
```

The technical model can exist underneath.

The shopkeeper sees the conclusion.

------------------------------------------------------------------------

# 52. Responsive Behavior

Primary target:

-   Android smartphones
-   Small and medium screens
-   One-handed usage

Design for:

``` text
360 × 800
390 × 844
412 × 915
```

Minimum touch target:

``` text
44 × 44 px
```

Prefer bottom-reachable actions.

Important buttons should not be placed exclusively at the top.

------------------------------------------------------------------------

# 53. Accessibility

Use:

-   Strong contrast
-   Large touch targets
-   Clear labels
-   Icons + text where necessary
-   Never rely only on color
-   Readable typography
-   Voice as an alternative input
-   Clear focus/pressed states

Examples:

Do not show only:

``` text
🔴
```

Instead:

``` text
Low stock
```

------------------------------------------------------------------------

# 54. Motion

Motion should communicate state.

Good motion:

-   Product detected
-   Scan progress
-   Completed transaction
-   Bottom sheet transition
-   Confirmation

Avoid:

-   Constant floating elements
-   Decorative particle effects
-   Glowing AI animations
-   Long transitions

Target:

``` text
Fast
Subtle
Functional
```

------------------------------------------------------------------------

# 55. Design System Components

Create reusable components:

``` text
AppHeader
BottomNavigation
PrimaryButton
SecondaryButton
IconButton
SearchBar
FilterChip
StatusBadge
Metric
BusinessAlert
ProductRow
CustomerRow
TransactionRow
RecommendationRow
CameraOverlay
ScanProgress
AIResponse
VoiceButton
ConfirmationSheet
BottomSheet
EmptyState
ErrorState
Toast
SkeletonLoader
```

------------------------------------------------------------------------

# 56. Component Principles

## Buttons

Primary:

-   Solid semantic primary color
-   High contrast
-   Short label

Good:

> Add to inventory

Bad:

> Proceed with inventory synchronization

## Cards

Use cards only where grouping helps.

Do not put every piece of information inside a card.

## Rows

Rows are preferred for:

-   Inventory
-   Customers
-   Transactions
-   Alerts
-   Recommendations

Rows are easier to scan than large cards.

------------------------------------------------------------------------

# 57. Core Screen Architecture

The application should have this information architecture:

``` text
DUKAANOS
│
├── Home
│   ├── Today's performance
│   ├── Alerts
│   ├── Quick actions
│   ├── AI update
│   └── Recent activity
│
├── Sales
│   ├── New Sale
│   │   ├── Barcode
│   │   └── AI Basket
│   └── Sales history
│
├── Inventory
│   ├── All
│   ├── Low stock
│   ├── Expiring
│   ├── Mismatch
│   └── Product detail
│
├── Khata
│   ├── Customers
│   └── Customer detail
│
└── More
    ├── Suppliers
    ├── Reports
    ├── Expiry
    ├── Stock adjustments
    ├── Settings
    └── Help
```

Cross-functional AI:

``` text
Ask Dukaan
```

should be accessible from Home and available as a global action.

------------------------------------------------------------------------

# 58. Hero User Journey

The primary demo journey should be:

``` text
1. Open DukaanOS
        ↓
2. Scan shop
        ↓
3. Inventory automatically created
        ↓
4. Scan supplier invoice
        ↓
5. Inventory increases
        ↓
6. Scan customer basket
        ↓
7. Bill generated
        ↓
8. Inventory decreases
        ↓
9. Ask "Kal kya order karna hai?"
        ↓
10. AI recommends order
        ↓
11. Perform stock audit
        ↓
12. Physical vs ERP mismatch detected
```

The UI should make this journey feel continuous.

------------------------------------------------------------------------

# 59. Hackathon MVP Screens

For the initial prototype, prioritize these screens:

### Tier 1 --- Must have

1.  Onboarding
2.  Home
3.  Scan My Shop
4.  Invoice Scanner
5.  New Sale
6.  AI Basket
7.  Stock Audit
8.  Ask Dukaan
9.  Inventory
10. Khata

### Tier 2 --- Strong supporting screens

11. Product Detail
12. Customer Detail
13. Audit Result
14. Business Insights
15. Expiry
16. Sales History

### Tier 3 --- Later

17. Supplier management
18. Reports
19. Advanced settings
20. Multi-store
21. Financing
22. Supplier marketplace

Do not allow Tier 3 features to compromise the quality of Tier 1.

------------------------------------------------------------------------

# 60. What NOT to Build in the UI

Do not make the first prototype attempt to expose:

-   GST filing
-   Full accounting
-   Payroll
-   Employee management
-   Supplier marketplace
-   E-commerce
-   Delivery network
-   Complex CRM
-   Thousands of manually configured products
-   Enterprise permissions
-   Complex accounting reports

The UI should focus on the core value proposition.

------------------------------------------------------------------------

# 61. Brand Direction

Brand name:

# DukaanOS

Possible descriptor:

> **The zero-entry ERP for every small shop.**

The brand should feel:

-   Indian without relying on clichés
-   modern without being futuristic
-   trustworthy
-   approachable
-   operational

Avoid obvious AI branding.

Do not put "AI" in the logo.

Do not use robot imagery.

------------------------------------------------------------------------

# 62. Design North Star

Every UI decision should pass this test:

> **Could a busy shopkeeper understand this screen within 3 seconds?**

And a second test:

> **Does this screen reduce work, or does it create another task?**

If a feature creates additional manual work, simplify the interaction.

------------------------------------------------------------------------

# 63. Final Design Principle

DukaanOS should not look like software that asks:

> "What would you like to enter?"

It should look like software that says:

> "I saw what happened. Here's what I updated. Here's what you should
> know."

The strongest visual and interaction pattern is therefore:

``` text
OBSERVE
Camera / Voice / Sensors
        ↓
UNDERSTAND
On-device AI
        ↓
UPDATE
ERP
        ↓
CHECK
Reconciliation
        ↓
PREDICT
Demand / expiry / stock
        ↓
ACT
Order / sell / adjust / collect
```

The application should make this loop feel effortless.

## Final Product Feeling

When a shopkeeper opens DukaanOS, the experience should communicate:

> **"I don't need to learn ERP software. My phone already understands my
> shop."**
