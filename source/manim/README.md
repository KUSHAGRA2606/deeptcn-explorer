# DeepTCN in motion: Manim animations

3Blue1Brown-style animations of DeepTCN (Chen et al., 2020) and our four extensions,
made with [Manim Community Edition](https://www.manim.community/), the maintained fork
of [3b1b/manim](https://github.com/3b1b/manim).

| # | Scene | What it shows |
|---|---|---|
| 1 | `Intro` | many related series → one shared network → a range of future values |
| 2 | `ForecastWindow` | 168 h history, 24 h forecast, 10/50/90% quantiles, the objective P(y₍t+1:t+24₎ \| y₍1:t₎, X) |
| 3 | `DilatedConvolution` | dilated causal convolutions and the receptive field growing layer by layer |
| 4 | `EncoderDecoder` | encoder summary hₜ, shared decoder, all horizons in parallel; autoregressive error build-up |
| 5 | `PinballLoss` | the pinball loss and how its minimum tracks the true quantile |
| 6 | `ConformalCalibration` | Ext 1: CQR shrinking a too-wide interval to 80%, ACI adapting under a shift |
| 7 | `CountHeads` | Ext 2: Gaussian vs negative binomial vs zero-inflated Poisson |
| 8 | `MemoryMask` | Ext 3: the soft memory mask, τ, and annealing |
| 9 | `CrossSeriesAttention` | Ext 4: attention between lanes and the attention matrix |
| 10 | `Results` | coverage before/after calibration and the lessons learned |

`DeepTCN_in_motion.mp4` is all ten chapters joined into one film.

## Render

```bash
pip install manim matplotlib          # Python 3.9+
manim -r 1920,1080 --fps 30 deeptcn_scenes.py Intro        # one scene
manim -ql deeptcn_scenes.py Intro                          # quick low-quality preview
python concat_film.py media/videos/deeptcn_scenes/1080p30 DeepTCN_in_motion.mp4
```

No LaTeX installation is needed: formulas are typeset with matplotlib's TeX engine
(mathtext, Computer Modern font) into vector SVGs and animated like any other shape.

`contact_sheet.py` builds a grid of frames from the rendered clips, which is handy for
checking layouts.
