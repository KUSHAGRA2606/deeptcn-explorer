# DeepTCN Explorer

An interactive, beginner-friendly website for our DA3041 (Applied Time Series Analysis,
IIT Guwahati) project on **probabilistic forecasting with temporal convolutional networks**:
DeepTCN (Chen et al., 2020), its replication on traffic and electricity data, and four
extensions.

**Live site:** https://kushagra2606.github.io/deeptcn-explorer/

The site is written entirely in **R** (shiny, bslib, ggplot2) and runs **in the visitor's
browser** through shinylive / webR. There is no server: the first load takes about
30–60 seconds while R starts in the browser.

## Animations: DeepTCN in motion

Ten 3Blue1Brown-style chapters made with [Manim](https://www.manim.community/), the
animation engine behind 3Blue1Brown, plus the full film (about 3 minutes):

- **Watch the full film:** [`videos/DeepTCN_in_motion.mp4`](videos/DeepTCN_in_motion.mp4)
- **Chapters:** intro · forecast window · dilated convolutions · encoder → decoder ·
  pinball loss · calibration (CQR / ACI) · count heads · learned memory · attention · results

They are also on the **Animations** page of the site. The source is in `source/manim/`.

## What's inside the site

| Page | Interactive demos |
|---|---|
| Home | data-flow animation, project goal, key results |
| Animations | the Manim film and its ten chapters |
| The problem | related series, the 168 h → 24 h window, train/val/calib/test splits |
| DeepTCN model | dilated causal convolutions and receptive field, encoder → decoder walkthrough, autoregressive vs direct forecasting, pinball loss, per-window scaling |
| Replication | our results vs the paper, training curve, metric playground |
| Ext 1 · Calibration | CQR / ACI playground with distribution shift, our real coverage results, ACI guarantee calculator |
| Ext 2 · Count heads | Gaussian vs negative binomial vs zero-inflated Poisson, the count-resolution trap |
| Ext 3 · Memory | soft memory mask, annealing, padded histories, learned τ on traffic |
| Ext 4 · Attention | attention matrix, neighbour mixing, permutation test, results |
| Theory | formula cheat sheet with intuitions, animated interval-score demo |
| Summary | what we learned, future ideas |

Each page also has collapsible **Theory & formulas** panels.

## Repository layout

```
index.html, app.json, shinylive/, shinylive-sw.js   the exported static site (served by GitHub Pages)
videos/                                               Manim film + 10 chapters (used by the Animations page)
source/app/app.R                                      the Shiny app (single file)
source/app/data/                                      result CSVs from the DeepTCN_Forecasting repo
source/app/deeptcn_dataflow.mp4                       data-flow animation (Home page)
source/manim/                                         Manim scenes, film builder, README
source/patch_index.py                                 post-export polish (dark splash, title)
```

## Run the app locally

```r
install.packages(c("shiny", "bslib", "ggplot2"))
shiny::runApp("source/app")
```

To get the Animations page locally, copy the `videos/` folder into `source/app/videos/`.
See `source/app/README.md` for details.

## Rebuild the site

```r
install.packages("shinylive")
shinylive::export("source/app", "site")     # export without the videos folder inside the app
```

Then run `python source/patch_index.py site/index.html`, copy `videos/` to `site/videos/`,
and copy the contents of `site/` to the repository root.

## Authors

Sudipto Ghosh · Kushagra Singhal · Sujal Patnaik · Pratham Saluja (Group 2)

Code for the experiments: https://github.com/sudipto818/DeepTCN_Forecasting
