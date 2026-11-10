"""Join the rendered scene clips into one film (re-encoded H.264, web friendly)."""
import os
import sys

import av

SCENES = ["Intro", "ForecastWindow", "DilatedConvolution", "EncoderDecoder", "PinballLoss",
          "ConformalCalibration", "CountHeads", "MemoryMask", "CrossSeriesAttention", "Results"]

src, out = sys.argv[1], sys.argv[2]
first = av.open(os.path.join(src, SCENES[0] + ".mp4"))
vs = first.streams.video[0]
W, H, rate = vs.codec_context.width, vs.codec_context.height, vs.average_rate
first.close()

from fractions import Fraction

dst = av.open(out, "w", options={"movflags": "+faststart"})
st = dst.add_stream("libx264", rate=rate)
st.width, st.height, st.pix_fmt = W, H, "yuv420p"
st.time_base = Fraction(rate.denominator, rate.numerator)
st.options = {"crf": "23", "preset": "medium"}
n = 0
for name in SCENES:
    with av.open(os.path.join(src, name + ".mp4")) as c:
        for frame in c.decode(video=0):
            f = av.VideoFrame.from_ndarray(frame.to_ndarray(format="rgb24"), format="rgb24")
            f.pts = n
            for pkt in st.encode(f):
                dst.mux(pkt)
            n += 1
for pkt in st.encode():
    dst.mux(pkt)
dst.close()
print("wrote", out, n, "frames", f"{n / float(rate):.1f} s")
