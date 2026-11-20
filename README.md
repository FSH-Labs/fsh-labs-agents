# FSH Labs laser cutting: the API and MCP server for AI agents

FSH Labs is a laser cutting shop an AI agent can order from: it prices a DXF or SVG in acrylic, wood or Delrin in one call, with no account and no API key, and hands the person a link to pay.

FSH Labs is a one-person laser shop in metro Atlanta. It cuts flat parts up to 23.2 x 11.6 in in 20 materials, has them ready in 7 - 10 business days and ships in the US.

| | |
| - | - |
| MCP server | `https://www.fshlabs.com/mcp` (Streamable HTTP, no authentication) |
| HTTP API | `https://www.fshlabs.com/agents/v1` (no key) |
| OpenAPI 3.1 | [openapi.json](openapi.json), live at https://www.fshlabs.com/agents/v1/openapi.json |
| The guide an agent reads | [AGENTS.md](AGENTS.md), live at https://www.fshlabs.com/agents.md |
| For people | https://www.fshlabs.com/laser-cutting/api and https://www.fshlabs.com/agents/mcp |

## Price a part in one call

```sh
curl -s https://www.fshlabs.com/agents/v1/quote \
  -F file=@examples/plate.dxf \
  -F material=birch-125 \
  -F qty=20 \
  -F ship_zip=30126
```

The answer has the price, the price at quantities 1 to 250, the same part in other materials, shipping to the ZIP code and the total before tax. `examples/plate.dxf` is a 4 x 4 in plate with five holes.

## Add the MCP server

**Claude Code** (steps run end to end on 2026-11-19, https://www.fshlabs.com/agents/claude-code):

```sh
claude mcp add --transport http fshlabs https://www.fshlabs.com/mcp
```

Any other client that speaks MCP over Streamable HTTP: point it at `https://www.fshlabs.com/mcp`. There is nothing to install and no token to set.

## Or just tell your agent

```text
Read https://www.fshlabs.com/agents.md and price my part with FSH Labs.
```

## The 10 operations

Each is an MCP tool and an HTTP call. Only the ones marked make anything; the rest are read-only.

| Tool | HTTP | What it does | Makes something |
| - | - | - | - |
| `get_catalog` | `GET /agents/v1/catalog` | Materials, limits, lead time and policies |  |
| `quote_laser_file` | `POST /agents/v1/quote` | Price a DXF or SVG |  |
| `create_order` | `POST /agents/v1/orders` | Make a payment link for the person | yes |
| `get_order_status` | `GET /agents/v1/orders/{order_id}/{status_token}` | Where an order stands |  |
| `request_custom_quote` | `POST /agents/v1/quote-requests` | Ask a person at the shop for a price | yes |
| `list_templates` | `GET /agents/v1/templates` | Parts that need no drawing |  |
| `quote_template` | `POST /agents/v1/quote/template` | Price a part from a template |  |
| `list_products` | `GET /agents/v1/products` | Personalized products |  |
| `quote_product` | `POST /agents/v1/quote/product` | Price a personalized product |  |
| `quote_order` | `POST /agents/v1/quote-order` | Price several things as one order |  |

## What it does not do

- Cut metal. We mark stainless, aluminum and brass with a fiber laser, but that is quoted by a person.
- Read STEP or other 3D files. The instant quote takes a DXF or SVG: a flat outline, drawn to size.
- Charge anything. Every order ends in a link the person opens and pays themselves. An agent never holds a card.
- Rush. Every order is ready in 7 - 10 business days, and there is no faster option at any price.
- Fix a drawing. Parts are cut exactly as sent, so fit and dimensions are the customer's.
- Take parts over 23.2 x 11.6 in, or ship outside the US.
- Scale without limit. It is one person's shop: past 200 agent-made orders in a day the API says so and sends the person to the website.

For sheet metal an agent can order, see the dated comparison at https://www.fshlabs.com/agents/compare.

## About this repository

Every file here is generated from the code that runs https://www.fshlabs.com, so it cannot drift from the live service. Do not open pull requests against the generated files; write to chaz@fshlabs.com or open an issue instead.

The examples and documents here are MIT licensed. The service is run by FSH Labs.
