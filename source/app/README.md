# DeepTCN Explorer: run it locally

An interactive website about our DA3041 project: DeepTCN (Chen et al., 2020), its
replication on traffic and electricity data, and four extensions. It is written
entirely in R (shiny, bslib, ggplot2).

Online version (no install needed): https://kushagra2606.github.io/deeptcn-explorer/

---

## What's in this folder

Keep all of these together. The app reads the video and the data from this folder.

```
app/
├── app.R                    the whole website (pages, demos, plots)
├── deeptcn_dataflow.mp4     the data-flow animation on the Home page
├── data/                    21 CSV files with our experiment results
└── README.md                this file
```

## Requirements

| Requirement | Details |
|---|---|
| R | version 4.1 or newer (https://cran.r-project.org) |
| RStudio | optional, but the easiest way to run it (https://posit.co/download/rstudio-desktop) |
| R packages | `shiny`, `bslib`, `ggplot2` |
| Internet | needed once, to install the packages; also needed for formulas to display (see the note below) |
| Browser | any modern browser (Chrome, Edge, Firefox, Safari) |

## Steps

**1. Copy the folder.** Copy the whole `app` folder to your computer (for example from a
pendrive). Do not copy `app.R` on its own.

**2. Install the packages (once).** Open R or RStudio and run:

```r
install.packages(c("shiny", "bslib", "ggplot2"))
```

**3. Run the app.** Use either option:

- **RStudio:** open `app.R` and click the **Run App** button at the top of the editor.
- **R console:** point R at the folder and run it:

  ```r
  shiny::runApp("C:/path/to/app")      # use the real path to this folder
  ```

The website opens in your browser within a few seconds. Keep R running while you use it,
and press **Esc** (or the red Stop button in RStudio) to close it.

## Using the site

- Use the top menu to move between pages: Home → The problem → DeepTCN model →
  Replication → Ext 1–4 → Theory → Summary.
- Move the sliders to change a demo; every plot updates instantly.
- Press **▶** under a slider to animate it.
- Open the **Theory & formulas** panels at the bottom of a page for the maths.

## Notes

- **Formulas need internet.** They are drawn by MathJax, which loads online. Offline,
  everything else works, but formulas show as raw LaTeX text.
- **Package warnings** such as "package was built under R version …" are harmless.
- **"cannot open file 'data/...'" or a missing video** means the `data` folder or the
  `.mp4` file is not next to `app.R`. Copy the whole folder.

## Authors

Sudipto Ghosh · Kushagra Singhal · Sujal Patnaik · Pratham Saluja (Group 2), IIT Guwahati
