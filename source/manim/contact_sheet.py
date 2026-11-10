"""Contact sheet of frames from rendered scenes (for checking layouts)."""
import glob
import os
import sys

import av
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
order = ["Intro", "ForecastWindow", "DilatedConvolution", "EncoderDecoder", "PinballLoss",
         "ConformalCalibration", "CountHeads", "MemoryMask", "CrossSeriesAttention", "Results"]
tiles = []
for name in order:
    f = glob.glob(os.path.join(src, name + ".mp4"))
    if not f:
        continue
    with av.open(f[0]) as c:
        n = sum(1 for _ in c.decode(video=0))
    want = {int(n * 0.45), n - 1}
    with av.open(f[0]) as c:
        for i, fr in enumerate(c.decode(video=0)):
            if i in want:
                tiles.append(fr.to_image().convert("RGB").resize((480, 270)))
cols = 4
rows = (len(tiles) + cols - 1) // cols
sheet = Image.new("RGB", (480 * cols, 270 * rows), (0, 0, 0))
for i, im in enumerate(tiles):
    sheet.paste(im, ((i % cols) * 480, (i // cols) * 270))
sheet.save(out)
print(len(tiles), "frames")
