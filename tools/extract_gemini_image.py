#!/usr/bin/env python3
"""Extract the inline base64 image from a Gemini API JSON response into a PNG.

Usage:
    python3 tools/extract_gemini_image.py file.json assets/tile_residential.png

The image lives at candidates[].content.parts[].inlineData.data (base64).
"""

import base64
import json
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    data = json.load(open(src))
    for cand in data.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inlineData") or part.get("inline_data")
            if inline and inline.get("data"):
                raw = base64.b64decode(inline["data"])
                with open(dst, "wb") as f:
                    f.write(raw)
                print(f"wrote {dst} ({len(raw)} bytes)")
                return 0
    print("no inline image found in", src)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
