#!/usr/bin/env python3
"""Turn an image into a square tile with a transparent background.

Center-crops to a square, then flood-fills the background to transparent
starting from the borders (so colors inside the subject are preserved), and
resizes to SIZE.

Usage:
    python3 tools/make_tile.py in.png out.png [size] [tolerance]
"""

import sys
from collections import deque

from PIL import Image


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 256
    tol = int(sys.argv[4]) if len(sys.argv) > 4 else 50

    im = Image.open(src).convert("RGBA")
    w, h = im.size
    s = min(w, h)
    im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
    W, H = im.size
    px = im.load()

    corners = [px[0, 0], px[W - 1, 0], px[0, H - 1], px[W - 1, H - 1]]

    def is_bg(c) -> bool:
        return any(abs(c[0] - k[0]) + abs(c[1] - k[1]) + abs(c[2] - k[2]) <= tol * 3
                   for k in corners)

    seen = bytearray(W * H)
    dq = deque()
    for x in range(W):
        for y in (0, H - 1):
            dq.append((x, y))
    for y in range(H):
        for x in (0, W - 1):
            dq.append((x, y))

    cleared = 0
    while dq:
        x, y = dq.popleft()
        if x < 0 or x >= W or y < 0 or y >= H or seen[y * W + x]:
            continue
        seen[y * W + x] = 1
        c = px[x, y]
        if not is_bg(c):
            continue
        px[x, y] = (c[0], c[1], c[2], 0)
        cleared += 1
        dq.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    im = im.resize((size, size), Image.LANCZOS)
    im.save(dst)
    print(f"wrote {dst} ({size}x{size}, {cleared} bg px cleared)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
