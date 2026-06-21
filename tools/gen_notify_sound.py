#!/usr/bin/env python3
"""Generate a soft two-tone notification 'ding' for crisis toasts (issue #36).

Placeholder SFX. Re-run: `python3 tools/gen_notify_sound.py`.
"""

import math
import struct
import wave

RATE = 44100
DUR = 0.28
OUT = "assets/notify.wav"


def main():
    frames = []
    for i in range(int(RATE * DUR)):
        t = i / RATE
        env = math.exp(-6.0 * t)  # gentle exponential decay
        s = 0.3 * env * (math.sin(2 * math.pi * 880 * t)
                         + 0.5 * math.sin(2 * math.pi * 1320 * t))
        frames.append(int(max(-1.0, min(1.0, s)) * 32767))
    with wave.open(OUT, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", f) for f in frames))
    print(f"wrote {OUT} ({DUR}s, {RATE}Hz)")


if __name__ == "__main__":
    main()
