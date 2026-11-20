#!/bin/sh
# Price examples/plate.dxf: 20 pieces in 1/8 in birch plywood, shipped to 30126.
# No key and no account. Run from the repository root.
curl -s https://www.fshlabs.com/agents/v1/quote \
  -F file=@examples/plate.dxf \
  -F material=birch-125 \
  -F qty=20 \
  -F ship_zip=30126
