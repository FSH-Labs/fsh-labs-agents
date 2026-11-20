# Ordering from FSH Labs with an AI agent

FSH Labs laser cuts acrylic, wood and Delrin in metro Atlanta, Georgia, and ships across the US. An AI agent can price a DXF or SVG, a part from a template or a personalized product, and hand the person a link to pay, with no account, no API key and nothing to install. Every order is ready in 7 - 10 business days.

- HTTP API: https://www.fshlabs.com/agents/v1 (JSON over HTTPS. Open to any origin.)
- OpenAPI: https://www.fshlabs.com/agents/v1/openapi.json (The same operations, described for machines.)
- MCP server: https://www.fshlabs.com/mcp (Streamable HTTP, no authentication. The same operations as tools.)
- This guide as markdown: https://www.fshlabs.com/agents.md

## Ground rules

- Use it on a person's behalf. They pay; you never see a card.
- The order minimum is $25 before shipping, with no setup fee, and it is charged once for an order however many items it holds. Quantity discounts are automatic.
- Several parts, materials or products can be one order with one pay link and one parcel: price the set with quote_order, then send the same items to create_order.
- Parts are cut exactly as drawn. Fit and dimensions are the customer's, so confirm sizes with them.
- Parts up to 23.2 x 11.6 in. Outlines must be closed. Text must be converted to outlines.
- We ship in the US only, and there is no rush service.
- Don't invent a price. If you can't call the API, send the person to the quote page below.

Example: 6 x 4 in plate with four holes, Birch plywood, 20 parts comes to $53.40 ($2.67 each) before shipping and tax.

## 1. See what we cut

`GET /agents/v1/catalog` (MCP tool `get_catalog`)

Every material and thickness with its slug, the size limits, the order minimum, the lead time and the issue codes a quote can return.

`design_rules` is what to draw to if you make the file yourself: the kerf, the smallest gap between cuts, and how far a real sheet strays from its listed thickness. `policies` covers remakes and what happens to files.

```sh
curl -s https://www.fshlabs.com/agents/v1/catalog
```

```json
{
  "materials": [
    {
      "slug": "birch-125",
      "name": "Birch plywood",
      "family": "wood",
      "thickness_in": 0.125,
      "quote_url": "https://www.fshlabs.com/laser-cutting/online-quote?material=birch-125"
    },
    "..."
  ],
  "limits": {
    "file_formats": [
      "dxf",
      "svg"
    ],
    "max_part_in": {
      "long": 23.2,
      "short": 11.6
    },
    "max_inline_file_bytes": 4194304
  },
  "pricing": {
    "order_minimum_cents": 2500,
    "setup_fee_cents": 0
  },
  "lead_time": "7 - 10 business days"
}
```

## 2. Price a file

`POST /agents/v1/quote` (MCP tool `quote_laser_file`)

Send the file one of four ways: a multipart upload in a field named `file`; `file_url`, a public https link (up to 10 MB); `file_text`, the file's own text, since DXF and SVG are both plain text (up to 4 MB, with `file_name`); or `file_base64` (up to 4 MB, with `file_name`).

The answer carries a `file_id`. Use it for every later call, so the file is only sent once: change `qty` or `material` and quote again as often as you like.

A file that can't be priced instantly still answers 200, with `priceable: false` and `issues` saying why. `block` issues stop the order. `review` issues are priced and a person checks them before cutting.

When a line doesn't close, `file.open_lines` gives where its two ends are and the gap between them, and `file.islands` gives where each loose shape sits, so a file you drew yourself can be fixed and sent again.

When `file.units_source` is `assumed`, the file didn't say inches or millimetres. Read the sizes back to the person before ordering, or pass `units`. Parts are cut exactly as drawn.

`price_breaks` is the same job at other quantities, so one call answers how the price falls with more. Send `compare_materials` (slugs, or `all`) to price the same file in other materials too.

Prices are before shipping and sales tax. Send `ship_zip` and the answer adds `shipping` and `total_before_tax`, so the person sees the whole price before any order is made. The same engine prices the website, so the number matches what the person would see there.

A field the operation doesn't take is refused with `unknown_fields`, never silently dropped.

```sh
curl -s https://www.fshlabs.com/agents/v1/quote \
  -F file=@plate.dxf \
  -F material=birch-125 \
  -F qty=20
```

```json
{
  "priceable": true,
  "file_id": "f_9KqT2mXv4LpR7sWz1aBcDe",
  "file": {
    "name": "plate.dxf",
    "format": "dxf",
    "units": "in",
    "units_source": "file",
    "parts": [
      {
        "label": "Part 1",
        "count": 1,
        "width_in": 6,
        "height_in": 4,
        "pierces": 5
      }
    ]
  },
  "material": {
    "slug": "birch-125",
    "name": "Birch plywood",
    "thickness_in": 0.125
  },
  "qty": 20,
  "price": {
    "currency": "usd",
    "each_cents": 267,
    "parts_cents": 5340,
    "minimum_top_up_cents": 0,
    "subtotal_cents": 5340,
    "display": "$53.40"
  },
  "price_breaks": [
    {
      "qty": 1,
      "each_cents": 642,
      "subtotal_cents": 2500
    },
    {
      "qty": 2,
      "each_cents": 507,
      "subtotal_cents": 2500
    },
    {
      "qty": 5,
      "each_cents": 387,
      "subtotal_cents": 2500
    },
    {
      "qty": 10,
      "each_cents": 302,
      "subtotal_cents": 3020
    },
    {
      "qty": 20,
      "each_cents": 267,
      "subtotal_cents": 5340
    },
    {
      "qty": 25,
      "each_cents": 256,
      "subtotal_cents": 6400
    },
    {
      "qty": 50,
      "each_cents": 215,
      "subtotal_cents": 10750
    },
    {
      "qty": 100,
      "each_cents": 194,
      "subtotal_cents": 19400
    },
    {
      "qty": 250,
      "each_cents": 194,
      "subtotal_cents": 48500
    }
  ],
  "other_materials": [],
  "shipping": null,
  "total_before_tax": null,
  "excludes": [
    "shipping",
    "sales_tax"
  ],
  "lead_time": "7 - 10 business days (unstocked sheet can add time)",
  "issues": [],
  "next": {
    "recommended": "create_order",
    "create_order": "POST /agents/v1/orders"
  }
}
```

## 3. Make a payment link

`POST /agents/v1/orders` (MCP tool `create_order`)

Saves the job as an unpaid order and answers with `pay_url`. Give that link to the person. It opens a page showing the order with a button to pay by card on Stripe, where they enter their address and any sales tax is added. You never handle a card.

`fulfilment` is `ship` (UPS Ground, US only, needs `ship_zip`) or `pickup` (free, metro Atlanta).

Nothing is made and nobody is charged until they pay. The prices hold for 30 days.

Send an `Idempotency-Key` header so a retry returns the same order instead of making a second one.

`tell_the_person` is a ready sentence with the total and the link.

For several things in one order, send `items` instead of one thing's fields (step 10): one pay link, one order minimum and one parcel for the lot.

```sh
curl -s https://www.fshlabs.com/agents/v1/orders \
  -H 'content-type: application/json' \
  -H 'idempotency-key: 6f1c2a9e' \
  -d '{"file_id":"f_9KqT2mXv4LpR7sWz1aBcDe","material":"birch-125","qty":20,"fulfilment":"ship","ship_zip":"30126"}'
```

```json
{
  "order_id": "FSH-20261118-K7M2QX",
  "pay_url": "https://www.fshlabs.com/pay/FSH-20261118-K7M2QX/...",
  "status_url": "https://www.fshlabs.com/agents/v1/orders/FSH-20261118-K7M2QX/...",
  "price": {
    "parts_cents": 5340,
    "minimum_top_up_cents": 0,
    "shipping_cents": "priced to the ZIP",
    "total_before_tax_cents": "parts + minimum + shipping"
  },
  "valid_until": "2026-12-18T04:59:59.999Z",
  "tell_the_person": "Your order FSH-20261118-K7M2QX is saved ... Open the link to check it and pay by card."
}
```

## 4. Check the order

`GET /agents/v1/orders/{order_id}/{status_token}` (MCP tool `get_order_status`)

GET the `status_url` from step 3 exactly as given. It reads status only: it can't pay and it can't download the file, so it is safe to keep.

```sh
curl -s https://www.fshlabs.com/agents/v1/orders/FSH-20261118-K7M2QX/...
```

```json
{
  "order_id": "FSH-20261118-K7M2QX",
  "status": "approved",
  "status_label": "In production",
  "paid": true,
  "lead_time": "7 - 10 business days (unstocked sheet can add time)",
  "shipped": null
}
```

## 5. Or ask a person for a price

`POST /agents/v1/quote-requests` (MCP tool `request_custom_quote`)

For anything the instant quote can't do: a file with block issues, a PDF, photo or sketch, engraving or marking, a material that isn't listed, or 500 or more of a part.

It needs the person's real name and email, because a person at the shop replies to it within 24 hours. We send that address nothing automatically, so tell them it was sent.

Hand-quoted work has a $25 minimum. Send one request per job.

```sh
curl -s https://www.fshlabs.com/agents/v1/quote-requests \
  -H 'content-type: application/json' \
  -d '{"name":"Dana Reyes","email":"dana@example.com","qty":4,"details":"12 x 8 in sign in 1/4 in birch with our logo engraved. File attached.","files":[{"file_id":"f_9KqT2mXv4LpR7sWz1aBcDe"}]}'
```

```json
{
  "request_id": "L-3FA9C1D2",
  "received": true,
  "files_received": [
    "plate.dxf"
  ],
  "what_happens_next": "The shop has the request ... A person replies within 24 hours with a price and a pay link."
}
```

## 6. No drawing? List the part templates

`GET /agents/v1/templates` (MCP tool `list_templates`)

26 parts the shop cuts from dimensions alone, for a person with no CAD file. Each lists its parameters with defaults and limits. Lengths are in inches.

```sh
curl -s https://www.fshlabs.com/agents/v1/templates
```

```json
{
  "templates": [
    {
      "slug": "mounting-plate",
      "name": "Mounting plate",
      "unit": "part",
      "params": [
        {
          "key": "width",
          "label": "Plate width",
          "kind": "length",
          "unit": "in",
          "default": 6,
          "min": 0.75,
          "max": 23
        },
        {
          "key": "height",
          "label": "Plate height",
          "kind": "length",
          "unit": "in",
          "default": 4,
          "min": 0.75,
          "max": 11.5
        },
        "..."
      ]
    },
    "..."
  ]
}
```

## 7. Price a template part

`POST /agents/v1/quote/template` (MCP tool `quote_template`)

Send the template's slug, any `values` that differ from its defaults, a `material` and a `qty`. Values that don't make a part are refused with the reason in plain words. `price_breaks` and `ship_zip` work as they do for a file.

To order it, call step 3 with `"kind": "laser-template"` and the same `template`, `values`, `material` and `qty`. Read the sizes back to the person first: the part is cut to exactly these numbers.

```sh
curl -s https://www.fshlabs.com/agents/v1/quote/template \
  -H 'content-type: application/json' \
  -d '{"template":"mounting-plate","values":{"width":6,"height":4},"material":"birch-125","qty":20}'
```

```json
{
  "priceable": true,
  "template": {
    "slug": "mounting-plate",
    "name": "Mounting plate",
    "unit": "part"
  },
  "values": {
    "width": 6,
    "height": 4,
    "...": "every other parameter, at its default"
  },
  "qty": 20,
  "price": {
    "each_cents": 267,
    "subtotal_cents": 5340,
    "display": "$53.40"
  },
  "lead_time": "7 - 10 business days (unstocked sheet can add time)"
}
```

## 8. List personalized products

`GET /agents/v1/products` (MCP tool `list_products`)

63 products the shop supplies and marks with the person's text, each with its colours, price by quantity, fonts and text limits. There is no order minimum on these, and no setup fee.

A product with `orderable_here: false` takes only a logo or photo, which can't be sent through the API yet: give the person its `url`.

```sh
curl -s https://www.fshlabs.com/agents/v1/products
```

```json
{
  "products": [
    {
      "slug": "tumbler-20oz",
      "name": "20 oz insulated tumbler",
      "orderable_here": true,
      "variants": [
        {
          "slug": "black",
          "label": "Black",
          "extra_cents": 0
        },
        {
          "slug": "white",
          "label": "White",
          "extra_cents": 0
        }
      ],
      "price_tiers": [
        {
          "min_qty": 1,
          "each_cents": 2200
        },
        {
          "min_qty": 10,
          "each_cents": 1900
        },
        {
          "min_qty": 25,
          "each_cents": 1750
        },
        {
          "min_qty": 50,
          "each_cents": 1650
        },
        {
          "min_qty": 100,
          "each_cents": 1600
        }
      ],
      "fonts": [
        {
          "key": "sans",
          "label": "Sans"
        },
        "..."
      ],
      "max_text_lines": 3
    },
    "..."
  ]
}
```

## 9. Price a personalized product

`POST /agents/v1/quote/product` (MCP tool `quote_product`)

Send the product, a `variant` (a colour or size), the `text`, a `font` and a `qty`. For a different name on each piece, send `names` too.

To order it, call step 3 with `"kind": "personalize"` and the same fields. After they pay, the person is emailed a proof to approve before anything is made, so read the text back to them exactly as you sent it, spelling included.

```sh
curl -s https://www.fshlabs.com/agents/v1/quote/product \
  -H 'content-type: application/json' \
  -d '{"product":"tumbler-20oz","variant":"black","text":["Dana Reyes"],"font":"sans","qty":10}'
```

```json
{
  "priceable": true,
  "product": {
    "slug": "tumbler-20oz",
    "name": "20 oz insulated tumbler"
  },
  "variant": {
    "slug": "black",
    "label": "Black"
  },
  "text": [
    "Dana Reyes"
  ],
  "font": "sans",
  "qty": 10,
  "price": {
    "each_cents": 1900,
    "subtotal_cents": 19000,
    "display": "$190.00"
  },
  "proof": "After payment we email the person a proof to approve before anything is made.",
  "lead_time": "7 - 10 business days (blanks are ordered after you pay)"
}
```

## 10. Price several things as one order

`POST /agents/v1/quote-order` (MCP tool `quote_order`)

A project is rarely one part. Send every part as `items` and the answer prices them as ONE order: each item at its own quantity, one order minimum for the lot, and one parcel to one ZIP. `saved_vs_separate_cents` is what that saves against ordering each item alone.

An item is a file you already quoted (`file_id`, with its `material` and `qty`), a template part (`kind` "laser-template") or a personalized product (`kind` "personalize"). Up to 20 items. The same `file_id` can appear twice, for the same part in two materials.

You hold the list. Nothing is stored: to add, remove or change an item, change the list and call again. When the person is happy, send the same `items` to `create_order` (step 3) with `fulfilment` and `ship_zip`, and give them the one `pay_url`.

`needs_proof` and `proof_items` say which items get a proof before they are made. Cut files and template parts are made exactly as ordered, with no proof; personalized products get one. Everything leaves together, so an order with a proofed item waits for that approval. If the person wants the cut parts sooner, order them on their own.

```sh
curl -s https://www.fshlabs.com/agents/v1/quote-order \
  -H 'content-type: application/json' \
  -d '{"items":[{"file_id":"f_9KqT2mXv4LpR7sWz1aBcDe","material":"birch-125","qty":20},{"kind":"laser-template","template":"mounting-plate","values":{"width":6,"height":4},"material":"birch-125","qty":4},{"kind":"personalize","product":"tumbler-20oz","text":"Dana Reyes","qty":10}],"ship_zip":"30126"}'
```

```json
{
  "priceable": true,
  "items": [
    {
      "item": "Laser cut part, Birch plywood",
      "kind": "laser-file",
      "qty": 20,
      "each_cents": 267,
      "parts_cents": 5340,
      "needs_proof": false
    },
    "...",
    {
      "item": "20 oz insulated tumbler",
      "kind": "personalize",
      "qty": 10,
      "each_cents": 1900,
      "parts_cents": 19000,
      "needs_proof": true
    }
  ],
  "price": {
    "parts_cents": "every item's goods",
    "minimum_top_up_cents": 0,
    "subtotal_cents": "before shipping and sales tax"
  },
  "saved_vs_separate_cents": "what one order saves in order minimums",
  "shipping": {
    "zip": "30126",
    "cents": "one parcel, priced to the ZIP",
    "service": "UPS Ground"
  },
  "needs_proof": true,
  "proof_items": [
    2
  ],
  "lead_time": "7 - 10 business days",
  "next": {
    "create_order": "POST /agents/v1/orders with the same items, plus fulfilment and ship_zip"
  }
}
```

## If you can only read pages

Some assistants can fetch a page but can't send a file. You can still get the person to a price in one click: give them the quote page with the material and quantity already chosen. They drop their file in and the price appears, with nothing to sign up for.

The link is https://www.fshlabs.com/laser-cutting/online-quote?material=<slug>&qty=<n>. For example, 20 parts in Birch plywood: https://www.fshlabs.com/laser-cutting/online-quote?material=birch-125&qty=20

The three quotes also answer a plain GET with the same fields in the query string, so a price that needs no upload is one link: https://www.fshlabs.com/agents/v1/quote/template?template=mounting-plate&material=birch-125&qty=20 prices the plate above, https://www.fshlabs.com/agents/v1/quote/product?product=tumbler-20oz&text=Dana&qty=10 a personalized product, and https://www.fshlabs.com/agents/v1/quote?file_url=<a public https link to the file>&material=<slug>&qty=<n> a file that is already online.

For work the instant quote can't price, the request form is https://www.fshlabs.com/order.

## Materials

| slug | material | thickness | quote page |
|---|---|---|---|
| `acrylic-clear-063` | Clear acrylic | .063 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-063 |
| `acrylic-clear-118` | Clear acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-118 |
| `acrylic-clear-177` | Clear acrylic | .177 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-177 |
| `acrylic-clear-214` | Clear acrylic | .214 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-214 |
| `acrylic-clear-375` | Clear acrylic | .375 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-375 |
| `acrylic-clear-500` | Clear acrylic | .500 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-clear-500 |
| `acrylic-black-118` | Black acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-black-118 |
| `acrylic-white-118` | White acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-white-118 |
| `acrylic-red-118` | Red acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-red-118 |
| `acrylic-blue-118` | Blue acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-blue-118 |
| `acrylic-green-118` | Green acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-green-118 |
| `acrylic-yellow-118` | Yellow acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-yellow-118 |
| `acrylic-mirror-118` | Mirror acrylic | .118 in | https://www.fshlabs.com/laser-cutting/online-quote?material=acrylic-mirror-118 |
| `birch-125` | Birch plywood | .125 in | https://www.fshlabs.com/laser-cutting/online-quote?material=birch-125 |
| `birch-250` | Birch plywood | .250 in | https://www.fshlabs.com/laser-cutting/online-quote?material=birch-250 |
| `mdf-125` | MDF | .125 in | https://www.fshlabs.com/laser-cutting/online-quote?material=mdf-125 |
| `mdf-250` | MDF | .250 in | https://www.fshlabs.com/laser-cutting/online-quote?material=mdf-250 |
| `hardboard-125` | Hardboard | .125 in | https://www.fshlabs.com/laser-cutting/online-quote?material=hardboard-125 |
| `delrin-125` | Delrin (acetal) | .125 in | https://www.fshlabs.com/laser-cutting/online-quote?material=delrin-125 |
| `polypropylene-030` | Polypropylene | .030 in | https://www.fshlabs.com/laser-cutting/online-quote?material=polypropylene-030 |

## File issue codes

- `no-outline` - block: nothing in the file is a closed outline. https://www.fshlabs.com/guidelines/laser-cutting#closed-outlines
- `open-outline` - block: the part's outside edge doesn't close. https://www.fshlabs.com/guidelines/laser-cutting#closed-outlines
- `loose-islands` - block: shapes inside a cutout would fall out; it is engraving artwork, quoted by a person. https://www.fshlabs.com/guidelines/laser-cutting#text-and-images
- `too-large` - review: bigger than the laser bed; priced, then checked by a person. https://www.fshlabs.com/guidelines/laser-cutting#part-size
- `too-small` - review: under 1/4 in on its short side; priced, then checked. https://www.fshlabs.com/guidelines/laser-cutting#part-size
- `cleaned-up` - review: tiny gaps were closed or doubled lines dropped. https://www.fshlabs.com/guidelines/laser-cutting#closed-outlines
- `not-cut` - review: text and images in the file are ignored, only outlines are cut. https://www.fshlabs.com/guidelines/laser-cutting#text-and-images

## Errors

Every refusal is `{ "error": { "code", "message", ... } }` with a matching HTTP status.

- `invalid-request` - A field is missing or wrong (`fields` names each one), or the request carries a field this operation doesn't take (`unknown_fields`, with `valid` listing the ones it does). Fix and send again.
- `unsupported-format` - Only DXF and SVG are priced instantly. `accepted` lists them. For any other file, send a custom quote request.
- `file-too-large` - Over 4 MB sent inline, or over 10 MB by file_url. Send a link instead, or simplify the file.
- `file-unreadable` - The file is empty, damaged, or not what its name says. Export it again, or send a custom quote request.
- `file-fetch-failed` - We couldn't download file_url. It must be a public https link. Send the file as file_text or file_base64 instead.
- `file-not-found` - No file with that file_id (they are kept 30 days). Send the file again.
- `unknown-material` - Not a material slug. `valid` lists every slug.
- `unknown-template` - Not a template slug. `valid` lists every slug; list_templates describes them.
- `unknown-product` - Not a product slug. `valid` lists every slug; list_products describes them.
- `not-priceable` - The file has a problem that stops an instant order. `issues` says what. Fix the file or send a custom quote request.
- `rejected` - The order can't be taken as asked. The message says why.
- `ship-zip-required` - Shipping is priced to the ZIP. Send ship_zip, or use fulfilment pickup.
- `pickup-only` - This order is too big to ship. Use fulfilment pickup, or send a custom quote request.
- `not-found` - No order matches that status link, or there is no endpoint at that path (`endpoints` lists every one).
- `method-not-allowed` - That path exists, but not with that HTTP method. `allow` lists the ones it takes.
- `rate-limited` - Too many calls from this address. Wait `retry_after_s` seconds.
- `capacity` - The shop has taken all the agent orders it can today. Send the person to `human_url`.
- `unavailable` - A service we depend on is down. Retry after `retry_after_s`, or send the person to `human_url`.
- `internal` - Our fault. Try again in a minute.

## Limits

- Catalog and status: 120 calls a minute per address.
- Quotes, a whole order's included: 60 a minute per address, and 20 a minute with `ship_zip`.
- Payment links count once however many items the order holds, up to 20 items an order.
- Payment links: 10 an hour per address.
- Quote requests: 3 an hour per address, and 3 a day per email.
- A 429 carries `retry_after_s`. A 503 with code `capacity` means the shop has taken all it can today: send the person to `human_url`.
