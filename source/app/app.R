# DeepTCN Explorer -------------------------------------------------------------
# An interactive companion to our DA3041 project: DeepTCN (Chen et al., 2020),
# its replication on traffic and electricity, and four extensions.
# Built with shiny + bslib + ggplot2 only, so it runs in the browser via
# shinylive (webR) with no server.

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(ggplot2)
})

# ---------------------------------------------------------------- look & feel (dark)
BG <- "#0a1020"; CARD <- "#111a2e"; FG <- "#e2e8f0"; MUTED <- "#94a3b8"; GRID <- "#1e293b"; EDGE <- "#23304d"
COL <- c(blue = "#38bdf8", orange = "#fb923c", green = "#34d399", grey = "#94a3b8",
         pink = "#f472b6", yellow = "#facc15", sky = "#a78bfa", red = "#f87171", dark = FG)
METHOD_COL <- c("Raw DeepTCN" = COL[["grey"]], "CQR pooled" = COL[["sky"]],
                "CQR horizon" = COL[["blue"]], "CQR two-tail" = COL[["green"]],
                "ACI" = COL[["orange"]])
METHOD_LAB <- c(base = "Raw DeepTCN", cqr_pooled = "CQR pooled", cqr_horizon = "CQR horizon",
                cqr_twotail = "CQR two-tail", aci = "ACI")

dark_theme <- theme_minimal(base_size = 14) +
  theme(plot.background = element_rect(fill = CARD, colour = NA),
        panel.background = element_rect(fill = CARD, colour = NA),
        legend.background = element_rect(fill = CARD, colour = NA),
        legend.key = element_rect(fill = CARD, colour = NA),
        text = element_text(colour = FG),
        axis.text = element_text(colour = MUTED),
        panel.grid.major = element_line(colour = GRID, linewidth = 0.4),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(colour = MUTED, size = 11.5),
        legend.position = "bottom")
# ggplot2 >= 4: default ink/paper so un-styled lines, points and labels suit the dark card
if (exists("element_geom", asNamespace("ggplot2")))
  dark_theme <- dark_theme + theme(geom = ggplot2::element_geom(ink = FG, paper = CARD, accent = COL[["blue"]]))
theme_set(dark_theme)

app_theme <- bs_theme(
  version = 5, bg = BG, fg = FG,
  primary = COL[["blue"]], secondary = "#334155", success = COL[["green"]],
  warning = COL[["orange"]], danger = COL[["red"]], info = COL[["sky"]],
  base_font = font_collection("Segoe UI", "Inter", "Helvetica Neue", "Arial", "sans-serif"),
  "navbar-bg" = "#060b17", "card-bg" = CARD, "card-border-color" = EDGE,
  "card-cap-bg" = "#0f1830", "accordion-bg" = CARD, "border-color" = EDGE,
  "input-bg" = "#0f1830", "link-color" = COL[["blue"]]
)

css <- "
body{background:#0a1020}
@keyframes heroShift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
@keyframes pulseGlow{0%,100%{box-shadow:0 0 0 rgba(56,189,248,0)}50%{box-shadow:0 0 22px rgba(56,189,248,.35)}}
@keyframes floatDot{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}
.hero{background:linear-gradient(120deg,#0b1a3a,#1d4ed8,#0e7490,#7c3aed,#0b1a3a);background-size:300% 300%;
      animation:heroShift 14s ease infinite;color:#fff;border-radius:16px;padding:30px 32px;margin-bottom:18px;
      border:1px solid rgba(255,255,255,.08)}
.hero h1{font-weight:800;font-size:2.1rem;margin-bottom:6px;letter-spacing:-.5px}
.hero p{font-size:1.08rem;opacity:.93;margin:0}
.card{animation:fadeUp .55s ease both;transition:transform .2s ease, box-shadow .2s ease, border-color .2s ease}
.card:hover{transform:translateY(-2px);box-shadow:0 8px 28px rgba(56,189,248,.12);border-color:#2f4a7a}
.card-header{font-weight:700;color:#cfe7ff}
.step{border-left:4px solid #38bdf8;padding:10px 14px;background:rgba(56,189,248,.07);border-radius:10px;margin-bottom:8px;
      animation:fadeUp .5s ease both}
.step:nth-child(2){animation-delay:.08s}.step:nth-child(3){animation-delay:.16s}.step:nth-child(4){animation-delay:.24s}
.tag{display:inline-block;background:rgba(56,189,248,.16);color:#7dd3fc;border-radius:999px;padding:2px 10px;
     font-size:.85rem;font-weight:700;margin-right:6px}
.big-q{font-size:1.05rem;font-weight:700;color:#f8fafc}
.muted{color:#94a3b8;font-size:.92rem}
.kpi{font-size:1.7rem;font-weight:800;color:#38bdf8}
.vb-cyan{background:linear-gradient(135deg,#0369a1,#0891b2)!important;color:#fff!important;animation:pulseGlow 4s ease-in-out infinite}
.vb-orange{background:linear-gradient(135deg,#9a3412,#ea580c)!important;color:#fff!important}
.vb-green{background:linear-gradient(135deg,#065f46,#059669)!important;color:#fff!important}
.vb-violet{background:linear-gradient(135deg,#4c1d95,#7c3aed)!important;color:#fff!important}
.vb-slate{background:linear-gradient(135deg,#1e293b,#334155)!important;color:#fff!important}
.ok-box{border-color:#34d399!important;background:rgba(52,211,153,.10)!important}
.bad-box{border-color:#fb923c!important;background:rgba(251,146,60,.12)!important}
.navbar{border-bottom:1px solid #1e293b}
.navbar .nav-link{transition:color .2s}
.navbar .nav-link.active{color:#38bdf8!important;box-shadow:inset 0 -3px 0 #38bdf8}
.nav-tabs .nav-link.active{background:#111a2e!important;color:#38bdf8!important;border-color:#23304d #23304d #111a2e!important}
.irs--shiny .irs-bar{background:linear-gradient(90deg,#0ea5e9,#a78bfa);border:none}
.irs--shiny .irs-single,.irs--shiny .irs-from,.irs--shiny .irs-to{background:#0ea5e9}
.irs--shiny .irs-line{background:#1e293b;border:none}
.irs--shiny .irs-grid-text,.irs--shiny .irs-min,.irs--shiny .irs-max{color:#64748b;background:transparent}
.slider-animate-button{color:#38bdf8!important;font-size:1.15rem;animation:floatDot 2.4s ease-in-out infinite}
.table{color:#e2e8f0}
.formula-card .card-body{font-size:.98rem}
.mjx-chtml{color:#f1f5f9}
video{border-radius:12px;width:100%;background:#000;border:1px solid #23304d}
.recalculating{opacity:1!important;transition:none!important}
.shiny-plot-output img{transition:opacity .25s ease}
a{color:#38bdf8}
"

# formula helper: MathJax block inside an accordion
theory <- function(title = "Theory & formulas", ...) {
  accordion(open = FALSE,
            accordion_panel(title, icon = NULL, withMathJax(div(...))))
}
how_to <- function(...) div(class = "muted", style = "margin-bottom:8px", ...)

# ---------------------------------------------------------------- data
rd <- function(f) read.csv(file.path("data", f), stringsAsFactors = FALSE)
headline <- do.call(rbind, lapply(c("traffic", "electricity"), function(d)
  do.call(rbind, lapply(c("daily", "hourly"), function(p) rd(sprintf("headline_%s_seed1_%s.csv", d, p))))))
cov_h <- do.call(rbind, lapply(c("traffic", "electricity"), function(d)
  rd(sprintf("coverage_by_horizon_%s_seed1_hourly.csv", d))))
cov_d <- do.call(rbind, lapply(c("traffic", "electricity"), function(d)
  rd(sprintf("coverage_by_day_%s_seed1_hourly.csv", d))))
alpha_tr <- do.call(rbind, lapply(c("traffic", "electricity"), function(d)
  rd(sprintf("alpha_trace_%s_seed1_hourly.csv", d))))
example <- lapply(c(traffic = "traffic", electricity = "electricity"), function(d)
  rd(sprintf("example_series_%s_seed1_daily.csv", d)))
diag_raw <- rbind(transform(rd("diagnostic_traffic_seed1.csv"), dataset = "traffic"),
                  transform(rd("diagnostic_electricity_seed1.csv"), dataset = "electricity"))
paper_m <- do.call(rbind, lapply(c("traffic", "electricity"), function(d)
  do.call(rbind, lapply(c("daily", "hourly"), function(p) rd(sprintf("paper_metrics_%s_%s.csv", d, p))))))
ext2 <- rd("subset_ext2.csv")
ext34 <- rd("subset_ext34.csv")
train_log <- rd("training_traffic.csv")

PAPER <- data.frame(
  dataset = rep(c("traffic", "electricity"), each = 5),
  metric = rep(c("QL50", "QL90", "NRMSE", "SMAPE", "MASE"), 2),
  value = c(0.058, 0.040, 0.364, 0.110, 0.438, 0.057, 0.029, 0.523, 0.118, 0.926))

video_src <- tryCatch(
  paste0("data:video/mp4;base64,",
         jsonlite::base64_enc(readBin("deeptcn_dataflow.mp4", "raw", file.size("deeptcn_dataflow.mp4")))),
  error = function(e) "deeptcn_dataflow.mp4")

# ---------------------------------------------------------------- small helpers
sigmoid <- function(x) 1 / (1 + exp(-x))
pinball <- function(y, yhat, q) { d <- y - yhat; pmax(q * d, (q - 1) * d) }
conformal_q <- function(scores, alpha) {
  scores <- sort(scores[is.finite(scores)]); n <- length(scores)
  k <- ceiling((1 - alpha) * (n + 1))
  if (k > n) return(Inf)
  if (k < 1) return(-Inf)
  scores[k]
}
winkler <- function(y, lo, hi, alpha = 0.2) {
  w <- hi - lo + (2 / alpha) * pmax(lo - y, 0) + (2 / alpha) * pmax(y - hi, 0)
  mean(w[is.finite(w)])
}
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

# toy panel of related series (shared daily + weekly rhythm)
make_panel <- function(n_series, hours, share, seed) {
  set.seed(seed)
  t <- 0:(hours - 1)
  common <- sin(2 * pi * t / 24) + 0.5 * sin(2 * pi * t / 168)
  do.call(rbind, lapply(seq_len(n_series), function(i) {
    lvl <- runif(1, 1, 4); own <- sin(2 * pi * (t + runif(1, 0, 24)) / 24)
    data.frame(series = paste0("series ", i), t = t,
               y = pmax(0, lvl * (1 + 0.45 * (share * common + (1 - share) * own)) +
                          rnorm(hours, 0, 0.25)))
  }))
}

# ============================================================================
# UI
# ============================================================================
home_ui <- nav_panel(
  "Home",
  div(class = "hero",
      h1("DeepTCN Explorer"),
      p("Forecasting thousands of related time series at once, with uncertainty you can trust."),
      p(style = "margin-top:8px;font-size:.95rem",
        "We rebuilt DeepTCN (Chen et al., 2020), tested it on freeway traffic and household electricity, and extended it four ways. Every page below is interactive.")),
  layout_columns(
    col_widths = c(7, 5),
    card(card_header("Watch: how data flows through DeepTCN"),
         tags$video(src = video_src, controls = NA, autoplay = NA, muted = NA, loop = NA, playsinline = NA),
         div(class = "muted", "History goes through the dilated convolutional encoder, future calendar information through the decoder, and all 24 future hours come out at once.")),
    card(card_header("Our goal in one picture"),
         div(class = "step", span(class = "tag", "1"), "Many related series (963 traffic lanes, 370 electricity customers)."),
         div(class = "step", span(class = "tag", "2"), "One shared network forecasts the next 24 hours for every series, not just a single number but a range (10%, 50%, 90% quantiles)."),
         div(class = "step", span(class = "tag", "3"), "We check: is it accurate? Do its 80% ranges really contain 80% of the truth?"),
         div(class = "step", span(class = "tag", "4"), "Then we extend it: calibration, count distributions, adaptive memory, cross-series attention."))
  ),
  layout_columns(
    col_widths = c(3, 3, 3, 3),
    value_box("Traffic QL50 (ours)", "0.068", p("ahead of DeepAR, SQF-RNN, DeepState"), class = "vb-cyan"),
    value_box("Raw 80% intervals cover", "89% / 73%", p("traffic / electricity: miscalibrated"), class = "vb-orange"),
    value_box("After conformal calibration", "80.1%", p("traffic, with 15% narrower intervals"), class = "vb-green"),
    value_box("Extensions tested", "4", p("all reuse the same calibration layer"), class = "vb-violet")
  ),
  h4("The four extensions", style = "margin-top:10px;font-weight:700"),
  layout_columns(
    col_widths = c(3, 3, 3, 3),
    card(card_header("1 · Calibration"), p(class = "big-q", "Do 80% intervals cover 80%?"),
         p("CQR fixes stable data; ACI follows shifts like Christmas.")),
    card(card_header("2 · Count heads"), p(class = "big-q", "Better than quantiles?"),
         p("Negative binomial & zero-inflated Poisson: no, the quantile head still wins.")),
    card(card_header("3 · Learned memory"), p(class = "big-q", "Does every series need 168 h?"),
         p("A soft mask learns how far back to look; on full-history lanes it stays open.")),
    card(card_header("4 · Attention"), p(class = "big-q", "Can lanes borrow from neighbours?"),
         p("Attention finds lanes that move together, but accuracy does not improve."))
  ),
  div(class = "muted", style = "margin-top:6px",
      "Suggested path: Problem → Model → Training & metrics → Replication → Extensions 1–4 → Summary.")
)

problem_ui <- nav_panel(
  "The problem",
  layout_sidebar(
    sidebar = sidebar(
      width = 290,
      sliderInput("p_n", "Number of related series", 2, 25, 8),
      sliderInput("p_share", "How much they share a common rhythm", 0, 1, 0.8, step = 0.05),
      sliderInput("p_origin", "Forecast origin t (drag or press play)", 168, 600, 300, step = 12,
                  animate = animationOptions(interval = 750, loop = TRUE)),
      radioButtons("p_proto", "Evaluation protocol", c("daily (paper)" = "daily", "hourly (ours)" = "hourly"), inline = TRUE),
      actionButton("p_seed", "New random panel", class = "btn-outline-primary btn-sm")
    ),
    layout_columns(
      col_widths = c(6, 6, 12),
      card(card_header("Many series, one shared pattern"), plotOutput("p_panel", height = 300),
           how_to("Move the slider: with a high shared rhythm, one global model can learn from all series at once. That also helps a brand-new series with no history (cold start).")),
      card(card_header("What the model sees and predicts"), plotOutput("p_window", height = 300),
           how_to("Blue: the last 168 hours it may look at. Orange: the 24 hours it must forecast. Press play to slide the window.")),
      card(card_header("How the data is split in time (never peeking at the future)"), plotOutput("p_split", height = 170),
           uiOutput("p_split_txt"))
    ),
    theory(
      "Problem setup & formulas",
      p("We observe \\(N\\) related series \\(y^{(i)}_{1:T}\\) and covariates known in advance \\(X\\) (hour, weekday, month, series id). DeepTCN models the whole future window jointly:"),
      p("$$P\\big(y_{t+1:t+\\Omega} \\mid y_{1:t},\\, X\\big),\\qquad L = 168 \\text{ h in},\\ \\ \\Omega = 24 \\text{ h out}.$$"),
      p("Window at origin \\(t\\): input \\(y_{t-167:t}\\), target \\(y_{t+1:t+24}\\). Splits counted back from the end: test = last 7 days, calibration = 7 days before, validation = 14 days before that, training = everything earlier. The model is trained once and never retrained."),
      p("Data: traffic = PEMS-SF, 963 lanes × 10,560 h (occupancy); electricity = UCI, 370 customers × 26,304 h (kW).")
    )
  )
)

model_ui <- nav_panel(
  "DeepTCN model",
  navset_card_tab(
    nav_panel(
      "Dilated convolutions",
      layout_sidebar(
        sidebar = sidebar(
          width = 280,
          sliderInput("c_layers", "Residual blocks (press ▶ to grow the network)", 1, 7, 4, step = 1,
                      animate = animationOptions(interval = 1100, loop = TRUE)),
          sliderInput("c_k", "Kernel size k", 2, 3, 2, step = 1),
          radioButtons("c_dil", "Dilation", c("doubling 1,2,4,…" = "double", "all 1 (no dilation)" = "one")),
          radioButtons("c_nconv", "Convolutions per block", c("1" = 1, "2 (ours)" = 2), selected = 2, inline = TRUE),
          uiOutput("c_rf_box")
        ),
        plotOutput("c_tree", height = 430),
        how_to("Each dot is one hour at one layer. Orange dots are everything the final output (top right) depends on: its receptive field. It only ever looks left (causal), and doubling the dilation makes it grow exponentially."),
        theory(
          "Dilated causal convolution",
          p("$$s(t) = \\sum_{k=0}^{K-1} w(k)\\, x(t - d\\cdot k)$$"),
          p("Receptive field of \\(B\\) blocks with \\(n\\) convolutions each: $$r = 1 + n\\,(K-1)\\sum_{b=1}^{B} d_b.$$ Ours: \\(n=2, K=2, d=1,\\dots,32\\) gives \\(r = 1 + 2\\cdot 63 = 127\\) hours."),
          p("Each residual block: pad-left → conv → BatchNorm → ReLU → pad-left → conv → BatchNorm, then ReLU(out + input).")
        )
      )
    ),
    nav_panel(
      "Encoder → decoder",
      layout_sidebar(
        sidebar = sidebar(
          width = 280,
          sliderInput("f_step", "Step through the model", 1, 6, 1, step = 1,
                      animate = animationOptions(interval = 2200, loop = TRUE)),
          uiOutput("f_caption")
        ),
        plotOutput("f_flow", height = 380),
        theory(
          "Encoder, decoder and outputs",
          p("Encoder summary: \\(h_t = \\text{TCN}(y_{t-L+1:t}, X_{\\le t})\\)."),
          p("Decoder (resnet-v), shared by every horizon \\(j\\): $$R(X_{t+j}) = \\text{BN}(\\text{Dense}(\\text{ReLU}(\\text{BN}(\\text{Dense}(X_{t+j}))))),\\qquad \\delta_{t+j} = g\\big(h_t, R(X_{t+j})\\big)$$ The paper uses \\(g = R(X_{t+j}) + h_t\\), a neural version of ARIMAX: encoder = past dynamics, decoder = covariate effects."),
          p("Quantile head: \\(\\hat q_{0.1}, \\hat q_{0.5}, \\hat q_{0.9}\\). Likelihood head: parameters of a distribution (Gaussian, NB, ZIP).")
        )
      )
    ),
    nav_panel(
      "Why predict all hours at once?",
      layout_sidebar(
        sidebar = sidebar(
          width = 280,
          sliderInput("a_err", "Small model error per step", 0, 0.15, 0.05, step = 0.01),
          sliderInput("a_noise", "Noise in the data", 0.05, 1, 0.3, step = 0.05),
          actionButton("a_go", "Re-simulate", class = "btn-outline-primary btn-sm")
        ),
        plotOutput("a_plot", height = 360),
        how_to("Autoregressive models feed their own prediction back in, so small errors snowball with the horizon. DeepTCN predicts every horizon directly from the history, so errors do not compound.")
      )
    ),
    nav_panel(
      "Pinball loss",
      layout_sidebar(
        sidebar = sidebar(
          width = 280,
          sliderInput("q_q", "Quantile level q (press ▶ to sweep)", 0.05, 0.95, 0.9, step = 0.05,
                      animate = animationOptions(interval = 700, loop = TRUE)),
          selectInput("q_dist", "Shape of the data", c("skewed (like traffic)" = "skew", "symmetric" = "norm", "two peaks" = "bimodal")),
          actionButton("q_go", "New sample", class = "btn-outline-primary btn-sm")
        ),
        layout_columns(
          col_widths = c(6, 6),
          card(card_header("The loss for one point"), plotOutput("q_loss", height = 300)),
          card(card_header("Average loss over a sample"), plotOutput("q_risk", height = 300))
        ),
        how_to("The pinball loss punishes under- and over-prediction unequally. Whatever the shape of the data, the value that minimises the average loss (green) lands on the true q-quantile (dashed). That is why training on it gives quantile forecasts."),
        theory(
          "Pinball (quantile) loss",
          p("$$L_q(y,\\hat y) = q\\,(y-\\hat y)_+ + (1-q)\\,(\\hat y-y)_+$$"),
          p("\\(\\mathbb{E}[L_q(y,\\hat y)]\\) is minimised at \\(\\hat y = F^{-1}(q)\\). DeepTCN sums it over \\(q \\in \\{0.1, 0.5, 0.9\\}\\) and all 24 horizons.")
        )
      )
    ),
    nav_panel(
      "Scaling",
      layout_sidebar(
        sidebar = sidebar(
          width = 280,
          sliderInput("s_level", "Typical size of the series", 0.1, 200, 20),
          checkboxInput("s_zero", "Customer hasn't started yet (history all zero)", FALSE),
          radioButtons("s_rule", "Scale rule", c("mean |history| (floor 1e-6)" = "mean", "1 + mean |history|" = "plus1"))
        ),
        layout_columns(
          col_widths = c(6, 6),
          card(card_header("Before scaling"), plotOutput("s_before", height = 260)),
          card(card_header("What the network sees"), plotOutput("s_after", height = 260))
        ),
        uiOutput("s_msg"),
        theory(
          "Per-window scaling",
          p("Each window is divided by its own level so big and small series look alike: \\(\\tilde y = y / s\\), with \\(s = \\max(\\overline{|y_{t-167:t}|}, 10^{-6})\\), and predictions are multiplied back by \\(s\\)."),
          p("With an all-zero history, \\(s=10^{-6}\\) multiplies the targets by a million: one electricity target reached \\(4.3\\times10^{6}\\). DeepAR's rule \\(\\nu = 1 + \\overline{|y|}\\) avoids it.")
        )
      )
    )
  )
)

results_ui <- nav_panel(
  "Replication",
  layout_sidebar(
    sidebar = sidebar(
      width = 280,
      selectInput("r_metric", "Metric", c("QL50", "QL90", "NRMSE", "SMAPE", "MASE")),
      radioButtons("r_proto", "Our protocol", c("daily (paper's)" = "daily", "hourly" = "hourly"), inline = FALSE),
      hr(),
      h6("Metric playground"),
      sliderInput("m_bias", "Forecast bias", -1, 1, 0, step = 0.05),
      sliderInput("m_noise", "Forecast noise", 0, 1, 0.2, step = 0.05)
    ),
    layout_columns(
      col_widths = c(6, 6, 12),
      card(card_header("Our replication vs. the paper (lower is better)"), plotOutput("r_bar", height = 300),
           how_to("Traffic lands close to the paper. Electricity is weaker because late-starting customers broke the scaling (see the Model → Scaling tab).")),
      card(card_header("Training on traffic"), plotOutput("r_train", height = 300),
           how_to("The epoch is chosen on a separate validation block, never on the test week.")),
      card(card_header("Metric playground: what each score measures"),
           layout_columns(col_widths = c(8, 4), plotOutput("m_plot", height = 260), uiOutput("m_vals")))
    ),
    theory(
      "Accuracy metrics",
      p("$$\\text{QL}_q = \\frac{\\sum L_q(y,\\hat y_q)}{\\sum |y|},\\quad \\text{SMAPE} = \\overline{\\frac{2|y-\\hat y|}{|y|+|\\hat y|}},\\quad \\text{NRMSE} = \\frac{\\sqrt{\\overline{(y-\\hat y)^2}}}{\\overline{|y|}},\\quad \\text{MASE} = \\frac{\\overline{|y-\\hat y|}}{\\overline{|y_t-y_{t-24}|}}$$"),
      p("MASE < 1 means better than repeating yesterday's value for the same hour (seasonal naive).")
    )
  )
)

ext1_ui <- nav_panel(
  "Ext 1 · Calibration",
  navset_card_tab(
    nav_panel(
      "Playground",
      layout_sidebar(
        sidebar = sidebar(
          width = 300,
          sliderInput("e1_time", "▶ Play the test period", 40, 400, 400, step = 10,
                      animate = animationOptions(interval = 650, loop = FALSE)),
          sliderInput("e1_width", "Model's interval width (1 = perfect)", 0.4, 1.8, 1.4, step = 0.05),
          sliderInput("e1_ncal", "Calibration points", 20, 1000, 300, step = 20),
          sliderInput("e1_shift", "Shift in the test period (noise ×)", 1, 3, 1, step = 0.1),
          sliderInput("e1_shift_at", "Shift starts at test step", 0, 400, 150, step = 10),
          sliderInput("e1_gamma", "ACI step size γ", 0.001, 0.1, 0.02, step = 0.001),
          checkboxGroupInput("e1_show", "Show", c("Raw", "CQR", "ACI"), selected = c("Raw", "CQR", "ACI"), inline = TRUE),
          actionButton("e1_go", "New data", class = "btn-outline-primary btn-sm")
        ),
        uiOutput("e1_kpis"),
        layout_columns(
          col_widths = c(12, 6, 6),
          card(card_header("Test period: observations and 80% intervals"), plotOutput("e1_series", height = 280)),
          card(card_header("Rolling coverage (target 0.80)"), plotOutput("e1_roll", height = 250)),
          card(card_header("ACI's adaptive level αₜ"), plotOutput("e1_alpha", height = 250))
        ),
        how_to("Press ▶ on 'Play the test period' to watch the test week unfold. Try: width 1.4 (too wide) → CQR shrinks it to ~80%. Width 0.6 (too narrow) → CQR widens it. Shift 2× starting at step 150 → CQR under-covers, while ACI lowers αₜ and widens its intervals to catch up.")
      )
    ),
    nav_panel(
      "Our results",
      layout_sidebar(
        sidebar = sidebar(
          width = 260,
          radioButtons("e1r_ds", "Dataset", c("traffic", "electricity")),
          radioButtons("e1r_proto", "Protocol (table)", c("hourly", "daily"), inline = TRUE)
        ),
        layout_columns(
          col_widths = c(5, 7, 6, 6, 12),
          card(card_header("Coverage, width, Winkler"), tableOutput("e1r_table"),
               how_to("Coverage target 0.80. Lower width and Winkler are better.")),
          card(card_header("Coverage by horizon (hourly)"), plotOutput("e1r_h", height = 270)),
          card(card_header("Coverage per test day (hourly)"), plotOutput("e1r_d", height = 250),
               uiOutput("e1r_day_note")),
          card(card_header("ACI's level over the test week"), plotOutput("e1r_a", height = 250)),
          card(card_header("One series over the test week (daily protocol)"), plotOutput("e1r_ex", height = 250))
        )
      )
    ),
    nav_panel(
      "Theory",
      layout_columns(
        col_widths = c(7, 5),
        card(card_header("CQR and ACI"),
             withMathJax(
               p(strong("Conformity score"), " on a calibration week (negative = inside the interval): $$E = \\max(\\hat q_{0.1} - y,\\; y - \\hat q_{0.9})$$"),
               p(strong("CQR"), " (Romano et al., 2019): take the \\(\\lceil (1-\\alpha)(n+1)\\rceil\\)-th smallest score \\(Q\\) and use \\([\\hat q_{0.1}-Q,\\; \\hat q_{0.9}+Q]\\). If calibration and test are exchangeable: $$1-\\alpha \\le P(y \\in C) \\le 1-\\alpha+\\tfrac{1}{n+1}.$$"),
               p("Variants: ", em("pooled"), " (one Q), ", em("horizon"), " (one \\(Q_j\\) per horizon on scores divided by the series scale \\(s_i\\)), ", em("two-tail"), " (separate lower/upper offsets at \\(\\alpha/2\\))."),
               p(strong("ACI"), " (Gibbs & Candès, 2021) updates the level online, per horizon, using only errors already observed (delay \\(\\delta_j = j\\) hours): $$\\alpha_{t+1} = \\alpha_t + \\gamma\\,(\\alpha - \\text{err}_t).$$ If \\(\\alpha_t \\le 0\\) the interval becomes \\((-\\infty,\\infty)\\).")
             )),
        card(card_header("When is ACI's guarantee meaningful?"),
             sliderInput("b_T", "Test origins T", 5, 300, 145),
             sliderInput("b_g", "Step size γ", 0.001, 0.2, 0.02, step = 0.001),
             sliderInput("b_d", "Feedback delay δ", 1, 24, 24),
             uiOutput("b_out"),
             how_to("Our runs: daily (T = 7) gives 1.29 (no guarantee); hourly (T = 145) gives 0.44 (traffic) and 0.28 (electricity)."))
      )
    )
  )
)

ext2_ui <- nav_panel(
  "Ext 2 · Count heads",
  layout_sidebar(
    sidebar = sidebar(
      width = 290,
      sliderInput("d_mu", "Expected occupancy μ (press ▶ to morph)", 0.02, 3, 0.4, step = 0.1,
                  animate = animationOptions(interval = 700, loop = TRUE)),
      sliderInput("d_sigma", "Gaussian σ", 0.05, 2, 0.4, step = 0.05),
      sliderInput("d_a", "NB dispersion a", 0.01, 2, 0.3, step = 0.01),
      sliderInput("d_pi", "ZIP extra zeros π", 0, 0.8, 0.1, step = 0.02),
      radioButtons("d_u", "Count resolution u (y counted in steps of 1/u)", c(1, 10, 100), selected = 10, inline = TRUE)
    ),
    layout_columns(
      col_widths = c(7, 5, 6, 6),
      card(card_header("Three ways to describe tomorrow's value"), plotOutput("d_dist", height = 320),
           how_to("Red area = probability the Gaussian gives to impossible negative values. Ticks = the 10/50/90% quantiles each head would report.")),
      card(card_header("The 'resolution trap' of ZIP"), plotOutput("d_trap", height = 320),
           how_to("Poisson has variance = mean, so after counting in steps of 1/u its spread is fixed by u, not learned.")),
      card(card_header("Our result on 320 traffic lanes"), plotOutput("d_res", height = 270)),
      card(card_header("Takeaway"),
           p(class = "big-q", "The quantile head wins 4 of 5 metrics."),
           p("ZIP is second (its NRMSE edge is noise; traffic has almost no zeros). The negative binomial is worst and stopped earliest: its dispersion makes training harder."),
           p(class = "muted", "Each head is turned into the same three quantiles, so the calibration layer of Extension 1 works for all of them."))
    ),
    theory(
      "Likelihood heads",
      p("Negative binomial: $$P(Y=k) = \\frac{\\Gamma(k+r)}{k!\\,\\Gamma(r)}\\Big(\\frac{1}{1+a\\mu}\\Big)^{r}\\Big(\\frac{a\\mu}{1+a\\mu}\\Big)^{k},\\quad r = 1/a,\\quad \\text{Var} = \\mu + a\\mu^2$$"),
      p("Zero-inflated Poisson: $$P(Y=0) = \\pi + (1-\\pi)e^{-\\lambda},\\qquad P(Y=k) = (1-\\pi)\\frac{\\lambda^k e^{-\\lambda}}{k!}\\ (k\\ge1)$$"),
      p("Trained by negative log-likelihood on \\(c = \\text{round}(y\\cdot u)\\) with scale \\(\\nu = 1+\\overline{|y|}\\); quantiles are read from the fitted CDF and divided by \\(u\\). For Poisson, \\(\\text{Var}(y) = \\mathbb{E}[y]/u\\).")
    )
  )
)

ext3_ui <- nav_panel(
  "Ext 3 · Memory",
  layout_sidebar(
    sidebar = sidebar(
      width = 290,
      sliderInput("g_tau", "Memory length τ (hours, press ▶)", 0, 232, 72, step = 8,
                  animate = animationOptions(interval = 600, loop = TRUE)),
      sliderInput("g_prog", "Training progress (anneals the sharpness s)", 0, 1, 0.5, step = 0.05,
                  animate = animationOptions(interval = 650, loop = TRUE)),
      checkboxInput("g_pad", "Series started only 40 h ago (rest is padding)", TRUE)
    ),
    layout_columns(
      col_widths = c(6, 6, 12),
      card(card_header("The soft mask over the input window"), plotOutput("g_mask", height = 280),
           uiOutput("g_s_txt")),
      card(card_header("What the encoder receives"), plotOutput("g_input", height = 280),
           how_to("Grey: raw history. Blue: history × mask. Orange band: the mask itself, fed as a separate channel, so 'hidden' is not confused with 'observed zero'.")),
      card(card_header("Result on traffic lanes"), plotOutput("g_res", height = 230),
           how_to("All learned τ sit at 228–232 h, i.e. the gate stays fully open: traffic lanes have complete history, so nothing should be hidden. The gate is meant for short or padded histories (cold start)."))
    ),
    theory(
      "Learned memory length",
      p("$$m_i(l) = \\sigma\\!\\Big(\\frac{\\tau_i - l}{s}\\Big),\\qquad \\tau_i = \\tau_{\\max}\\,\\sigma(f(c_i)),\\qquad \\text{input} = [\\,y\\odot m,\\ m\\,]$$ with \\(l=0\\) the newest hour and a penalty \\(\\lambda\\,\\overline{\\tau_i/L}\\) in the loss."),
      p("Made to train: \\(\\tau_{\\max} = L + 4s_0\\) and an initial bias of 4, so the mask starts ≈ 0.98 everywhere (the model begins as plain DeepTCN); the mask channel's weights start at 0; \\(s\\) is annealed from \\(L/10\\) to 1 after a warm-up.")
    )
  )
)

ext4_ui <- nav_panel(
  "Ext 4 · Attention",
  layout_sidebar(
    sidebar = sidebar(
      width = 290,
      sliderInput("t_n", "Lanes", 8, 40, 24),
      sliderInput("t_groups", "Groups of co-moving lanes", 1, 6, 3),
      sliderInput("t_noise", "How fuzzy the learned embeddings are", 0, 2, 0.5, step = 0.1),
      sliderInput("t_alpha", "Attention weight α (press ▶)", -1, 1, 0.5, step = 0.1,
                  animate = animationOptions(interval = 750, loop = TRUE)),
      checkboxInput("t_diag", "Mask the diagonal (don't attend to yourself)", TRUE),
      uiOutput("t_lane_ui"),
      actionButton("t_go", "New lanes", class = "btn-outline-primary btn-sm")
    ),
    layout_columns(
      col_widths = c(6, 6, 6, 6),
      card(card_header("Who attends to whom (A)"), plotOutput("t_heat", height = 300),
           how_to("Lanes are sorted by group. Bright blocks = lanes paying attention to their own group. Untick the diagonal mask to see A collapse onto itself.")),
      card(card_header("Mixing a lane's summary with its neighbours"), plotOutput("t_mix", height = 300),
           how_to("h ← h + α·(A h). α starts at 0 (plain DeepTCN) and is learned.")),
      card(card_header("Is attention meaningful? Permutation test"), plotOutput("t_perm", height = 270)),
      card(card_header("Our result (320 traffic lanes)"), plotOutput("t_res", height = 270),
           how_to("Real data: coherence 0.190 vs 0.185 ± 0.001 for shuffled embeddings (p < 0.005), but no metric moved beyond ±3%. The learned α = −0.29."))
    ),
    theory(
      "Cross-series attention",
      p("$$A = \\text{softmax}\\Big(\\frac{EE^\\top}{\\sqrt d} - \\infty\\cdot I\\Big),\\qquad h \\leftarrow h + \\alpha\\,(A\\,h),\\qquad \\alpha_{\\text{init}} = 0$$"),
      p("Every training step sees one forecast origin for all lanes, so \\(A\\) spans the whole panel. Coherence \\(= \\frac1N\\sum_{i,k} A_{ik} C_{ik}\\) with \\(C\\) the correlation of de-seasonalised series, compared with 200 random relabellings.")
    )
  )
)

fcard <- function(title, intuition, ...) {
  card(class = "formula-card", card_header(title),
       p(class = "muted", intuition), withMathJax(div(...)))
}

theory_ui <- nav_panel(
  "Theory",
  div(class = "hero", h1("Theory cheat sheet"),
      p("Every formula behind the project, each with a one-line intuition. Open this page whenever a demo raises a 'why?'.")),
  layout_columns(
    col_widths = c(6, 6),
    card(card_header("Interval score in motion"),
         sliderInput("w_y", "Where the truth lands (press ▶)", -3, 3, -2.6, step = 0.2, width = "100%",
                     animate = animationOptions(interval = 450, loop = TRUE)),
         plotOutput("w_plot", height = 250),
         how_to("A good interval is narrow and still contains the truth. Inside, you only pay its width; outside, you pay an extra 2/α = 10× the miss distance.")),
    fcard("1 · Probabilistic forecasts", "Instead of one number, give a range with a promised hit rate.",
          p("Quantile: \\(q_\\tau = F^{-1}(\\tau)\\). The 80% interval is \\([q_{0.1}, q_{0.9}]\\)."),
          p("Coverage: $$\\widehat{\\text{cov}} = \\frac1n\\sum_{i} \\mathbf 1\\{\\ell_i \\le y_i \\le u_i\\} \\;\\overset{?}{\\approx}\\; 1-\\alpha = 0.8$$"),
          p("Winkler (interval) score, lower is better: $$W = (u-\\ell) + \\tfrac{2}{\\alpha}(\\ell-y)\\mathbf 1\\{y<\\ell\\} + \\tfrac{2}{\\alpha}(y-u)\\mathbf 1\\{y>u\\}$$"))
  ),
  layout_columns(
    col_widths = c(4, 4, 4),
    fcard("2 · Causal, dilated, residual", "Look only at the past, look far cheaply, and keep gradients flowing.",
          p("Causal dilated convolution: $$s(t)=\\sum_{k=0}^{K-1} w_k\\,x_{t-d k}$$"),
          p("Residual block: \\(\\;x \\mapsto \\text{ReLU}\\big(x + F(x)\\big)\\), so a block can default to the identity."),
          p("Batch norm: \\(\\hat z = \\dfrac{z-\\mu_B}{\\sqrt{\\sigma_B^2+\\epsilon}}\\,\\gamma+\\beta\\)."),
          p("Receptive field: \\(r = 1 + n(K-1)\\sum_b d_b = 127\\) h for our encoder.")),
    fcard("3 · Why direct beats autoregressive", "Fed-back mistakes compound; direct mistakes do not.",
          p("For an AR(1) model with coefficient error \\(\\epsilon\\) the \\(h\\)-step forecast is \\((\\phi+\\epsilon)^h y_t\\), so its bias"),
          p("$$(\\phi+\\epsilon)^h - \\phi^h \\approx h\\,\\phi^{h-1}\\epsilon$$ grows with \\(h\\)."),
          p("DeepTCN fits each horizon directly: \\(\\hat y_{t+j} = f_j(h_t, X_{t+j})\\), so errors at different \\(j\\) do not feed each other.")),
    fcard("4 · Learning quantiles", "The pinball loss is minimised exactly at the quantile.",
          p("$$L_q(y,\\hat y) = \\max\\{q(y-\\hat y),\\,(q-1)(y-\\hat y)\\}$$"),
          p("Setting the derivative of \\(\\mathbb E[L_q]\\) to zero: \\(-q\\,(1-F(\\hat y)) + (1-q)F(\\hat y) = 0 \\Rightarrow F(\\hat y) = q\\)."),
          p("Total loss: \\(\\sum_{q\\in\\{.1,.5,.9\\}}\\sum_{j=1}^{24} L_q\\big(y_{t+j}, \\hat q_{t+j}\\big)\\)."))
  ),
  layout_columns(
    col_widths = c(4, 4, 4),
    fcard("5 · Conformal guarantees", "Past errors on fresh data tell you how much to widen.",
          p("Exchangeability: the joint law of \\((Z_1,\\dots,Z_{n+1})\\) is unchanged by any permutation, so the test score is equally likely to fall at any rank."),
          p("Hence with \\(Q\\) the \\(\\lceil(1-\\alpha)(n+1)\\rceil\\)-th score: $$P\\big(E_{n+1}\\le Q\\big) \\ge 1-\\alpha.$$"),
          p("ACI: \\(\\alpha_{t+1}=\\alpha_t+\\gamma(\\alpha-\\text{err}_t)\\) gives \\(\\big|\\tfrac1T\\sum \\text{err}_t-\\alpha\\big| \\le \\tfrac{\\max(\\alpha_1,1-\\alpha_1)+\\gamma}{T\\gamma}\\) for any sequence.")),
    fcard("6 · Count likelihoods", "Non-negative, skewed data deserve non-negative, skewed distributions.",
          p("NB: \\(\\mathbb E=\\mu,\\ \\text{Var}=\\mu+a\\mu^2\\) (over-dispersed). ZIP: \\(\\mathbb E=(1-\\pi)\\lambda,\\ \\text{Var}=(1-\\pi)\\lambda(1+\\pi\\lambda)\\)."),
          p("Positivity via softplus: \\(\\mu = \\nu\\log(1+e^{z})\\), with DeepAR scale \\(\\nu = 1+\\overline{|y|}\\)."),
          p("Train by NLL: \\(-\\sum \\log p(c_{t+j}\\mid \\theta_{t+j})\\), with \\(c = \\text{round}(y\\,u)\\).")),
    fcard("7 · Mask gradients & attention", "Soft masks keep τ learnable; the softmax temperature sets how focused attention is.",
          p("Mask \\(m(l)=\\sigma((\\tau-l)/s)\\) has $$\\frac{\\partial m}{\\partial \\tau} = \\frac{m(1-m)}{s},$$ which is almost zero everywhere when \\(s\\) is small. That is why \\(s\\) starts large and is annealed."),
          p("Attention \\(A_{ik} = \\dfrac{e^{\\,e_i^\\top e_k/\\sqrt d}}{\\sum_{k'\\ne i} e^{\\,e_i^\\top e_{k'}/\\sqrt d}}\\); permutation p-value \\(=\\frac1B\\#\\{\\text{null}\\ge\\text{obs}\\}\\)."))
  )
)

summary_ui <- nav_panel(
  "Summary",
  div(class = "hero", h1("What we learned"),
      p("Accurate medians do not guarantee trustworthy intervals, and conformal calibration fixes that for any model without retraining.")),
  layout_columns(
    col_widths = c(4, 4, 4),
    card(card_header("Replication"),
         p("DeepTCN reproduces on traffic (QL50 0.068) with honest model selection, beating recurrent and state-space baselines."),
         p(class = "muted", "Evaluation details (scaling of late starters, the MASE denominator) mattered more than any model change.")),
    card(card_header("Calibration (Ext 1)"),
         p("Raw 80% intervals: 89% on traffic, 73–78% on electricity."),
         p("CQR → 80.1% on traffic with 15% narrower intervals. ACI → 79% on electricity despite the Christmas shift.")),
    card(card_header("Extensions 2–4"),
         p("Count heads, adaptive memory and attention: no accuracy gain on dense, full-history traffic."),
         p(class = "muted", "But each behaves as theory predicts: the gate stays open, attention finds co-moving lanes."))
  ),
  layout_columns(
    col_widths = c(6, 6),
    card(card_header("Ideas for the future"),
         tags$ul(
           tags$li("Scale by 1 + mean so late-starting series can't dominate training."),
           tags$li("Holiday covariates, so Christmas is expected rather than a shock."),
           tags$li("Shift-aware conformal methods (multi-γ ACI, horizon-specific steps)."),
           tags$li("Test the memory gate on cold-start series; use road geography for attention."))),
    card(card_header("Project & resources"),
         p("DA3041 Applied Time Series Analysis · IIT Guwahati · Group 2"),
         p("Sudipto Ghosh · Kushagra Singhal · Sujal Patnaik · Pratham Saluja"),
         p(tags$a(href = "https://github.com/sudipto818/DeepTCN_Forecasting", target = "_blank", "Code on GitHub"),
           " · ", tags$a(href = "https://doi.org/10.1016/j.neucom.2020.03.011", target = "_blank", "Original paper (Chen et al., 2020)")),
         p(class = "muted", "This site is written entirely in R (shiny, bslib, ggplot2) and runs in your browser via webR."))
  )
)

ui <- page_navbar(
  title = "DeepTCN Explorer",
  window_title = "DeepTCN Explorer: forecasting, calibration and extensions",
  theme = app_theme,
  header = tags$head(tags$style(HTML(css))),
  navbar_options = navbar_options(collapsible = TRUE),
  fillable = FALSE,
  home_ui, problem_ui, model_ui, results_ui, ext1_ui, ext2_ui, ext3_ui, ext4_ui, theory_ui, summary_ui
)

# ============================================================================
# SERVER
# ============================================================================
server <- function(input, output, session) {

  # ------------------------------------------------------------ the problem
  panel <- reactive({
    input$p_seed
    make_panel(input$p_n, 800, input$p_share, seed = 7 + input$p_seed)
  })

  output$p_panel <- renderPlot({
    d <- panel(); d <- d[d$t < 336, ]
    ggplot(d, aes(t, y, group = series)) +
      geom_line(colour = COL[["blue"]], alpha = 0.55, linewidth = 0.6) +
      scale_x_continuous(breaks = seq(0, 336, 24), labels = function(x) paste0("d", x / 24)) +
      labs(x = "time (days)", y = "value", subtitle = paste(input$p_n, "series, two weeks"))
  })

  output$p_window <- renderPlot({
    d <- panel(); d <- d[d$series == "series 1", ]
    t0 <- input$p_origin
    ggplot(d, aes(t, y)) +
      annotate("rect", xmin = t0 - 167, xmax = t0, ymin = -Inf, ymax = Inf, fill = COL[["blue"]], alpha = 0.12) +
      annotate("rect", xmin = t0 + 1, xmax = t0 + 24, ymin = -Inf, ymax = Inf, fill = COL[["orange"]], alpha = 0.25) +
      geom_line(colour = "#7f8ea8", linewidth = 0.6) +
      geom_line(data = d[d$t > t0 & d$t <= t0 + 24, ], colour = COL[["orange"]], linewidth = 1.2) +
      geom_vline(xintercept = t0, linetype = 2) +
      annotate("label", x = t0 - 84, y = max(d$y) * 1.05, label = "history: 168 h", colour = COL[["blue"]], size = 4) +
      annotate("label", x = t0 + 12, y = max(d$y) * 1.05, label = "24 h", colour = COL[["orange"]], size = 4) +
      coord_cartesian(xlim = c(t0 - 200, t0 + 40)) +
      labs(x = "hour", y = "value", subtitle = paste("origin t =", t0))
  })

  output$p_split <- renderPlot({
    seg <- data.frame(part = factor(c("train", "validation", "calibration", "test"),
                                    levels = c("train", "validation", "calibration", "test")),
                      start = c(0, 26, 40, 47), end = c(26, 40, 47, 54))
    ticks <- if (input$p_proto == "daily") 47 + 0:6 + 0.5 else seq(47, 54, length.out = 60)
    ggplot(seg) +
      geom_rect(aes(xmin = start, xmax = end, ymin = 0, ymax = 1, fill = part), colour = CARD) +
      geom_text(aes(x = (start + end) / 2, y = 0.5, label = part), colour = "white", fontface = "bold", size = 4.5) +
      geom_point(data = data.frame(x = ticks), aes(x, 1.25), shape = 25, fill = COL[["orange"]], colour = COL[["orange"]], size = 2.2) +
      scale_fill_manual(values = c(train = "#334155", validation = COL[["sky"]], calibration = COL[["green"]], test = COL[["orange"]]), guide = "none") +
      scale_x_continuous(breaks = c(26, 40, 47, 54), labels = c("−28 d", "−14 d", "−7 d", "end")) +
      labs(x = NULL, y = NULL, subtitle = "▼ = forecast origins in the test week") +
      theme(axis.text.y = element_blank(), panel.grid = element_blank())
  })

  output$p_split_txt <- renderUI({
    if (input$p_proto == "daily")
      how_to("Daily (paper): one forecast per test day → 7 test origins. Few samples, so interval guarantees are weak.")
    else how_to("Hourly (ours): one forecast every hour → 145 test origins and 145 calibration origins. Many more samples for calibration.")
  })

  # ------------------------------------------------------------ dilated convolution tree
  conv_layers <- reactive({
    B <- input$c_layers; n <- as.integer(input$c_nconv)
    d <- if (input$c_dil == "double") 2^(0:(B - 1)) else rep(1, B)
    rep(d, each = n)
  })
  output$c_rf_box <- renderUI({
    d <- conv_layers(); r <- 1 + (input$c_k - 1) * sum(d)
    div(class = "step", div("Receptive field"), div(class = "kpi", paste(r, "hours")),
        div(class = "muted", "ours (6 blocks, k = 2, 2 convs): 127 h"))
  })
  output$c_tree <- renderPlot({
    d <- conv_layers(); K <- input$c_k; L <- length(d)
    r <- 1 + (K - 1) * sum(d); W <- min(max(r + 6, 24), 140); Tm <- W
    act <- list(); act[[L + 1]] <- Tm
    for (l in L:1) act[[l]] <- sort(unique(unlist(lapply(act[[l + 1]], function(t) t - d[l] * (0:(K - 1))))))
    nodes <- do.call(rbind, lapply(0:L, function(l) data.frame(t = 1:Tm, layer = l)))
    nodes$on <- mapply(function(t, l) t %in% act[[l + 1]], nodes$t, nodes$layer)
    edges <- do.call(rbind, lapply(1:L, function(l) {
      src <- act[[l + 1]]
      do.call(rbind, lapply(src, function(t) data.frame(x = t - d[l] * (0:(K - 1)), y = l - 1, xend = t, yend = l)))
    }))
    edges <- edges[edges$x >= 1, ]
    ggplot() +
      geom_segment(data = edges, aes(x, y, xend = xend, yend = yend), colour = COL[["orange"]], alpha = 0.45, linewidth = 0.5) +
      geom_point(data = nodes, aes(t, layer, colour = on, size = on)) +
      scale_colour_manual(values = c(`FALSE` = "#26324d", `TRUE` = COL[["orange"]]), guide = "none") +
      scale_size_manual(values = c(`FALSE` = 1, `TRUE` = 2.2), guide = "none") +
      scale_y_continuous(breaks = 0:L, labels = c("input", paste0("conv ", 1:L, "  (d=", d, ")"))) +
      labs(x = "time step (newest on the right)", y = NULL,
           subtitle = sprintf("Output at the top right depends on the last %d steps", r)) +
      theme(panel.grid = element_blank())
  })

  # ------------------------------------------------------------ encoder/decoder walkthrough
  flow_steps <- list(
    c("1 · History in", "The last 168 hours of the target plus calendar features (hour, weekday, month) and a learned series embedding."),
    c("2 · Encoder", "Stacked dilated causal convolutions read the history and compress it into one summary vector hₜ."),
    c("3 · Future calendar", "For each of the next 24 hours we already know the hour, weekday and month: these go to the decoder."),
    c("4 · Decoder", "A small residual network R(·) turns each future hour's calendar into features, the same network for all 24 hours."),
    c("5 · Merge", "hₜ is combined with R(X₍ₜ₊ⱼ₎) for every horizon j at the same time: no step waits for the previous one."),
    c("6 · Outputs", "Each horizon gets three quantiles (10%, 50%, 90%), or the parameters of a distribution."))
  output$f_caption <- renderUI({
    s <- flow_steps[[input$f_step]]
    div(class = "step", h5(s[1], style = "font-weight:700"), p(s[2]))
  })
  output$f_flow <- renderPlot({
    k <- input$f_step
    bx <- data.frame(
      id = 1:6, x = c(1, 3, 1, 3, 5, 7), y = c(3, 3, 1, 1, 2, 2),
      lab = c("History\n168 h", "Encoder\ndilated TCN", "Future\ncalendar",
              "Decoder\nresnet-v", "Merge\nper horizon", "Outputs\n3 quantiles"))
    bx$state <- ifelse(bx$id == k, "now", ifelse(bx$id < k, "done", "later"))
    ar <- data.frame(x = c(1.75, 1.75, 3.75, 3.75, 5.75), y = c(3, 1, 3, 1, 2),
                     xend = c(2.25, 2.25, 4.25, 4.25, 6.25), yend = c(3, 1, 2.25, 1.75, 2))
    fut <- data.frame(x = 7 + seq(-0.6, 0.6, length.out = 24), y = 1.25)
    p <- ggplot() +
      geom_segment(data = ar, aes(x, y, xend = xend, yend = yend), arrow = arrow(length = unit(0.25, "cm")), colour = MUTED) +
      geom_tile(data = bx, aes(x, y, fill = state), width = 1.5, height = 1, colour = CARD, linewidth = 1) +
      geom_text(data = bx, aes(x, y, label = lab), size = 4.6, lineheight = 0.9,
                colour = ifelse(bx$state == "later", "#64748b", "white"), fontface = "bold") +
      scale_fill_manual(values = c(now = COL[["orange"]], done = COL[["blue"]], later = "#1b2640"), guide = "none") +
      coord_cartesian(xlim = c(0.2, 7.9), ylim = c(0.2, 3.7)) + theme_void() + theme(plot.background = element_rect(fill = CARD, colour = NA))
    if (k == 6) p <- p + geom_point(data = fut, aes(x, y), colour = COL[["orange"]], size = 2) +
      annotate("text", x = 7, y = 0.95, label = "24 horizons at once", colour = COL[["orange"]], size = 3.8)
    p
  })

  # ------------------------------------------------------------ autoregressive vs direct
  output$a_plot <- renderPlot({
    input$a_go
    set.seed(11 + input$a_go)
    # truth: a daily-seasonal signal; each model makes the SAME size of mistake per step
    H <- 24; R <- 400; e <- input$a_err; s <- input$a_noise
    season <- function(t) 3 + 2 * sin(2 * pi * t / 24)
    err_ar <- err_dir <- matrix(0, R, H)
    for (r in 1:R) {
      ph <- runif(1, 0, 24); ideal <- season(ph + 1:H)
      # autoregressive: each step starts from its own previous forecast, so mistakes are carried forward
      ar <- numeric(H); prev <- season(ph)
      for (h in 1:H) {
        step <- season(ph + h) - season(ph + h - 1)
        prev <- prev + step * (1 + e) + rnorm(1, 0, s * 0.25); ar[h] <- prev
      }
      # direct: every horizon is predicted from the history with an independent mistake of the same size
      dir <- ideal + (ideal - season(ph)) * e + rnorm(H, 0, s * 0.25)
      err_ar[r, ] <- abs(ar - ideal); err_dir[r, ] <- abs(dir - ideal)
    }
    d <- data.frame(h = rep(1:H, 2), err = c(colMeans(err_ar), colMeans(err_dir)),
                    model = rep(c("Autoregressive (feeds back its own forecast)", "Direct / DeepTCN (all horizons at once)"), each = H))
    ggplot(d, aes(h, err, colour = model)) + geom_line(linewidth = 1.3) + geom_point(size = 1.6) +
      scale_colour_manual(values = c(COL[["grey"]], COL[["blue"]]), name = NULL) +
      labs(x = "hours ahead", y = "error vs. the ideal forecast",
           subtitle = "Same mistake per step: it piles up only when forecasts are fed back in")
  })

  # ------------------------------------------------------------ pinball loss
  q_sample <- reactive({
    input$q_go; set.seed(3 + input$q_go)
    switch(input$q_dist,
           skew = rlnorm(800, 0, 0.6),
           norm = rnorm(800, 2, 0.7),
           bimodal = c(rnorm(500, 1, 0.3), rnorm(300, 3, 0.4)))
  })
  output$q_loss <- renderPlot({
    q <- input$q_q; u <- seq(-3, 3, length.out = 200)
    d <- data.frame(u = u, loss = pmax(q * u, (q - 1) * u))
    ggplot(d, aes(u, loss)) + geom_line(linewidth = 1.4, colour = COL[["blue"]]) +
      geom_vline(xintercept = 0, linetype = 3) +
      annotate("text", x = 1.8, y = max(d$loss) * 0.9, label = sprintf("slope %.2f\n(forecast too low)", q), colour = COL[["blue"]]) +
      annotate("text", x = -1.8, y = max(d$loss) * 0.9, label = sprintf("slope %.2f\n(forecast too high)", 1 - q), colour = COL[["blue"]]) +
      labs(x = "y − forecast", y = expression(L[q]))
  })
  output$q_risk <- renderPlot({
    y <- q_sample(); q <- input$q_q
    grid <- seq(quantile(y, 0.001), quantile(y, 0.999), length.out = 200)
    risk <- sapply(grid, function(g) mean(pinball(y, g, q)))
    best <- grid[which.min(risk)]; truth <- quantile(y, q)
    sc <- max(risk) / max(density(y)$y)
    ggplot() +
      geom_histogram(aes(y, after_stat(density) * sc), bins = 45, fill = "#334155", colour = NA, data = data.frame(y = y)) +
      geom_line(aes(grid, risk), data = data.frame(grid, risk), linewidth = 1.3, colour = COL[["blue"]]) +
      geom_vline(xintercept = truth, linetype = 2, linewidth = 0.9) +
      geom_point(aes(best, min(risk)), colour = COL[["green"]], size = 4) +
      labs(x = "candidate forecast", y = "average pinball loss",
           subtitle = sprintf("minimum at %.2f · true %d%% quantile %.2f", best, round(q * 100), truth))
  })

  # ------------------------------------------------------------ scaling
  s_data <- reactive({
    set.seed(5); t <- 1:192
    y <- input$s_level * (1 + 0.5 * sin(2 * pi * t / 24)) + rnorm(192, 0, input$s_level * 0.08)
    y <- pmax(y, 0)
    if (input$s_zero) y[1:168] <- 0
    hist <- y[1:168]; m <- mean(abs(hist))
    s <- if (input$s_rule == "mean") max(m, 1e-6) else 1 + m
    list(t = t, y = y, s = s, scaled = y / s)
  })
  output$s_before <- renderPlot({
    d <- s_data()
    ggplot(data.frame(t = d$t, y = d$y, part = ifelse(d$t <= 168, "history", "target")), aes(t, y, colour = part)) +
      geom_line(linewidth = 0.9) + scale_colour_manual(values = c(history = COL[["blue"]], target = COL[["orange"]]), name = NULL) +
      labs(x = "hour", y = "original units")
  })
  output$s_after <- renderPlot({
    d <- s_data()
    ggplot(data.frame(t = d$t, y = d$scaled, part = ifelse(d$t <= 168, "history", "target")), aes(t, y, colour = part)) +
      geom_line(linewidth = 0.9) + scale_colour_manual(values = c(history = COL[["blue"]], target = COL[["orange"]]), name = NULL) +
      labs(x = "hour", y = "scaled units", subtitle = sprintf("scale s = %s", format(signif(d$s, 3), scientific = TRUE)))
  })
  output$s_msg <- renderUI({
    d <- s_data(); big <- max(abs(d$scaled))
    if (big > 1e3)
      div(class = "step", class = "bad-box",
          strong("Problem! "), sprintf("The scaled target reaches %s. A few windows like this dominate the whole loss.", format(signif(big, 3), big.mark = ",")))
    else div(class = "step", class = "ok-box",
             strong("Fine. "), sprintf("Scaled values stay around 1 (max %.2f): every series looks alike to the network.", big))
  })

  # ------------------------------------------------------------ replication
  output$r_bar <- renderPlot({
    m <- input$r_metric
    ours <- paper_m[paper_m$protocol == input$r_proto, c("dataset", m)]
    names(ours)[2] <- "value"; ours$who <- paste("ours", input$r_proto)
    pap <- PAPER[PAPER$metric == m, c("dataset", "value")]; pap$who <- "paper (reported)"
    d <- rbind(ours, pap)
    ggplot(d, aes(dataset, value, fill = who)) + geom_col(position = position_dodge(0.75), width = 0.7) +
      geom_text(aes(label = fmt(value)), position = position_dodge(0.75), vjust = -0.4, size = 4) +
      scale_fill_manual(values = c(COL[["blue"]], "#64748b"), name = NULL) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) + labs(x = NULL, y = m)
  })
  output$r_train <- renderPlot({
    d <- train_log; b <- d[which.min(d$val), ]
    dl <- rbind(data.frame(epoch = d$epoch, loss = d$train, set = "train"), data.frame(epoch = d$epoch, loss = d$val, set = "validation"))
    ggplot(dl, aes(epoch, loss, colour = set)) + geom_line(linewidth = 1.1) +
      geom_point(data = b, aes(epoch, val), colour = COL[["orange"]], size = 3.5, inherit.aes = FALSE) +
      annotate("label", x = b$epoch, y = b$val + 0.03, label = sprintf("best epoch %d", b$epoch), size = 3.6) +
      geom_vline(xintercept = max(d$epoch), linetype = 3) +
      scale_colour_manual(values = c(train = COL[["blue"]], validation = COL[["orange"]]), name = NULL) +
      labs(y = "pinball loss (scaled)", subtitle = "early stop after 10 epochs without improvement")
  })
  m_data <- reactive({
    set.seed(21); t <- 1:120
    y <- 3 + 2 * sin(2 * pi * t / 24) + rnorm(120, 0, 0.3); y <- pmax(y, 0)
    f <- 3 + 2 * sin(2 * pi * t / 24) + input$m_bias + rnorm(120, 0, input$m_noise)
    data.frame(t = t, y = y, f = f)
  })
  output$m_plot <- renderPlot({
    d <- m_data()
    ggplot(d, aes(t)) + geom_line(aes(y = y, colour = "actual"), linewidth = 0.9) +
      geom_line(aes(y = f, colour = "median forecast"), linewidth = 0.9) +
      scale_colour_manual(values = c(actual = FG, `median forecast` = COL[["blue"]]), name = NULL) + labs(x = "hour", y = NULL)
  })
  output$m_vals <- renderUI({
    d <- m_data(); y <- d$y[25:120]; f <- d$f[25:120]
    naive <- mean(abs(d$y[25:120] - d$y[1:96]))
    vals <- c(QL50 = sum(pinball(y, f, 0.5)) / sum(abs(y)), SMAPE = mean(2 * abs(y - f) / (abs(y) + abs(f))),
              NRMSE = sqrt(mean((y - f)^2)) / mean(abs(y)), MASE = mean(abs(y - f)) / naive)
    tagList(lapply(names(vals), function(n)
      div(class = "step", span(n, style = "font-weight:700"), span(style = "float:right;font-weight:800", fmt(vals[[n]])))))
  })

  # ------------------------------------------------------------ ext 1 playground
  e1 <- reactive({
    input$e1_go
    set.seed(100 + input$e1_go)
    alpha <- 0.2; z <- qnorm(0.9)
    sim <- function(n, shift = rep(1, n)) {
      t <- 1:n; sd <- 0.5 + 0.35 * sin(2 * pi * t / 24)^2
      mu <- 2 + sin(2 * pi * t / 24)
      list(y = mu + rnorm(n, 0, sd * shift), mu = mu, sd = sd)
    }
    ncal <- input$e1_ncal; nt <- 400
    cal <- sim(ncal)
    shift <- ifelse(seq_len(nt) > input$e1_shift_at, input$e1_shift, 1)
    te <- sim(nt, shift)
    w <- input$e1_width
    lo_c <- cal$mu - z * cal$sd * w; hi_c <- cal$mu + z * cal$sd * w
    lo <- te$mu - z * te$sd * w; hi <- te$mu + z * te$sd * w
    Q <- conformal_q(pmax(lo_c - cal$y, cal$y - hi_c), alpha)
    scores <- pmax(lo_c - cal$y, cal$y - hi_c)
    a <- alpha; at <- numeric(nt); la <- ua <- numeric(nt); miss <- numeric(nt)
    for (t in 1:nt) {
      at[t] <- a; qa <- conformal_q(scores, a)
      la[t] <- lo[t] - qa; ua[t] <- hi[t] + qa
      miss[t] <- as.numeric(te$y[t] < la[t] | te$y[t] > ua[t])
      a <- a + input$e1_gamma * (alpha - miss[t])
    }
    list(t = 1:nt, y = te$y, lo = lo, hi = hi, lq = lo - Q, uq = hi + Q, la = la, ua = ua, at = at, Q = Q)
  })
  e1_metrics <- reactive({
    d <- e1(); i <- seq_len(input$e1_time); y <- d$y[i]
    m <- function(l, u) { l <- l[i]; u <- u[i]
      c(cov = mean(y >= l & y <= u), width = mean((u - l)[is.finite(u - l)]), wink = winkler(y, l, u)) }
    rbind(Raw = m(d$lo, d$hi), CQR = m(d$lq, d$uq), ACI = m(d$la, d$ua))
  })
  output$e1_kpis <- renderUI({
    m <- e1_metrics()
    box <- function(n, cl) value_box(paste(n, "· coverage so far"), sprintf("%.1f%%", 100 * m[n, "cov"]),
                                     p(sprintf("width %.2f · Winkler %.2f", m[n, "width"], m[n, "wink"])), class = cl)
    layout_columns(col_widths = c(4, 4, 4), box("Raw", "vb-slate"), box("CQR", "vb-green"), box("ACI", "vb-orange"))
  })
  output$e1_series <- renderPlot({
    d <- e1(); sh <- input$e1_show; Tn <- input$e1_time; k <- max(1, Tn - 149):Tn
    df <- data.frame(t = d$t[k], y = d$y[k])
    p <- ggplot(df, aes(t, y))
    if ("Raw" %in% sh) p <- p + geom_ribbon(aes(ymin = d$lo[k], ymax = d$hi[k]), fill = COL[["grey"]], alpha = 0.25)
    if ("CQR" %in% sh) p <- p + geom_line(aes(y = d$lq[k]), colour = COL[["green"]], linewidth = 0.9) + geom_line(aes(y = d$uq[k]), colour = COL[["green"]], linewidth = 0.9)
    if ("ACI" %in% sh) {
      ua <- d$ua[k]; la <- d$la[k]; ua[!is.finite(ua)] <- NA; la[!is.finite(la)] <- NA
      p <- p + geom_line(aes(y = la), colour = COL[["orange"]], linewidth = 0.9, linetype = 2) + geom_line(aes(y = ua), colour = COL[["orange"]], linewidth = 0.9, linetype = 2)
    }
    if (input$e1_shift > 1 && input$e1_shift_at %in% df$t) p <- p + geom_vline(xintercept = input$e1_shift_at, linetype = 3, colour = COL[["red"]]) +
      annotate("label", x = input$e1_shift_at, y = max(df$y), label = "shift begins", size = 3.5, colour = COL[["red"]])
    p + geom_point(size = 1.1, colour = FG) +
      geom_point(data = df[nrow(df), ], size = 3.5, colour = COL[["yellow"]]) +
      labs(x = "test step", y = "value", subtitle = sprintf("grey band = raw · green = CQR · orange dashed = ACI · step %d of 400", Tn))
  })
  output$e1_roll <- renderPlot({
    d <- e1(); W <- 40; Tn <- input$e1_time
    roll <- function(l, u) { inside <- as.numeric(d$y >= l & d$y <= u); as.numeric(stats::filter(inside, rep(1 / W, W), sides = 1)) }
    df <- rbind(data.frame(t = d$t, c = roll(d$lo, d$hi), m = "Raw DeepTCN"),
                data.frame(t = d$t, c = roll(d$lq, d$uq), m = "CQR two-tail"),
                data.frame(t = d$t, c = roll(d$la, d$ua), m = "ACI"))
    df <- df[df$m %in% c(if ("Raw" %in% input$e1_show) "Raw DeepTCN", if ("CQR" %in% input$e1_show) "CQR two-tail", if ("ACI" %in% input$e1_show) "ACI"), ]
    df <- df[df$t <= Tn, ]
    ggplot(df, aes(t, c, colour = m)) + geom_hline(yintercept = 0.8, linetype = 2) + geom_line(linewidth = 1.1, na.rm = TRUE) +
      geom_point(data = df[df$t == Tn, ], size = 3, na.rm = TRUE) + scale_x_continuous(limits = c(0, 400)) +
      scale_colour_manual(values = c("Raw DeepTCN" = COL[["grey"]], "CQR two-tail" = COL[["green"]], ACI = COL[["orange"]]),
                          labels = c("Raw DeepTCN" = "Raw", "CQR two-tail" = "CQR", ACI = "ACI"), name = NULL) +
      coord_cartesian(ylim = c(0.3, 1)) + labs(x = "test step", y = "coverage (last 40)")
  })
  output$e1_alpha <- renderPlot({
    d <- e1(); Tn <- input$e1_time
    df <- data.frame(t = d$t, a = d$at)[seq_len(Tn), ]
    ggplot(df, aes(t, a)) + geom_hline(yintercept = 0.2, linetype = 2) +
      geom_hline(yintercept = 0, linetype = 3, colour = MUTED) + geom_line(colour = COL[["orange"]], linewidth = 1.2) +
      geom_point(data = df[nrow(df), ], colour = COL[["yellow"]], size = 3.5) +
      scale_x_continuous(limits = c(0, 400)) + coord_cartesian(ylim = range(c(d$at, 0, 0.25))) +
      labs(x = "test step", y = expression(alpha[t]), subtitle = "falls after misses (wider intervals), rises after hits")
  })

  # ------------------------------------------------------------ ext 1 real results
  output$e1r_table <- renderTable({
    h <- headline[headline$dataset == input$e1r_ds & headline$protocol == input$e1r_proto, ]
    data.frame(Method = unname(METHOD_LAB[h$model]), Coverage = fmt(h$coverage), Width = fmt(h$width), Winkler = fmt(h$winkler))
  }, striped = TRUE, hover = TRUE, width = "100%")
  output$e1r_h <- renderPlot({
    d <- cov_h[cov_h$dataset == input$e1r_ds, ]; d$Method <- unname(METHOD_LAB[d$model])
    ggplot(d, aes(horizon, coverage, colour = Method)) + geom_hline(yintercept = 0.8, linetype = 2) +
      geom_line(aes(linewidth = Method %in% c("ACI", "CQR two-tail"))) +
      scale_linewidth_manual(values = c(`FALSE` = 0.7, `TRUE` = 1.4), guide = "none") +
      scale_colour_manual(values = METHOD_COL, name = NULL) + labs(x = "hours ahead", y = "coverage")
  })
  output$e1r_d <- renderPlot({
    d <- cov_d[cov_d$dataset == input$e1r_ds & cov_d$model %in% c("base", "cqr_twotail", "aci"), ]
    d$Method <- unname(METHOD_LAB[d$model])
    ggplot(d, aes(day, coverage, colour = Method)) + geom_hline(yintercept = 0.8, linetype = 2) +
      geom_line(linewidth = 1.1) + geom_point(size = 2.2) +
      scale_colour_manual(values = METHOD_COL, name = NULL) + scale_x_continuous(breaks = 1:7) + labs(x = "test day", y = "coverage")
  })
  output$e1r_day_note <- renderUI({
    if (input$e1r_ds == "electricity")
      how_to("Day 1 is Christmas Day 2014: consumption breaks from the calibration week, so CQR under-covers while ACI reacts.")
    else how_to("Traffic is stable: CQR and ACI both sit near 0.80 all week.")
  })
  output$e1r_a <- renderPlot({
    a <- alpha_tr[alpha_tr$dataset == input$e1r_ds, ]
    g <- aggregate(alpha ~ origin, a, mean); lo <- aggregate(alpha ~ origin, a, min); hi <- aggregate(alpha ~ origin, a, max)
    ggplot() + geom_ribbon(aes(x = lo$origin, ymin = lo$alpha, ymax = hi$alpha), fill = COL[["orange"]], alpha = 0.18) +
      geom_line(aes(g$origin, g$alpha), colour = COL[["orange"]], linewidth = 1.1) +
      geom_hline(yintercept = 0.2, linetype = 2) + geom_hline(yintercept = 0, linetype = 3, colour = MUTED) +
      labs(x = "hourly test origin", y = expression(alpha[t]), subtitle = "line = mean over horizons · band = range")
  })
  output$e1r_ex <- renderPlot({
    e <- example[[input$e1r_ds]]
    ggplot(e, aes(step)) + geom_ribbon(aes(ymin = lo_base, ymax = hi_base), fill = COL[["blue"]], alpha = 0.3) +
      geom_line(aes(y = lo_cqr), colour = COL[["orange"]], linetype = 2) + geom_line(aes(y = hi_cqr), colour = COL[["orange"]], linetype = 2) +
      geom_line(aes(y = actual), linewidth = 0.6) +
      scale_x_continuous(breaks = seq(12, 168, 24), labels = paste("day", 1:7)) +
      scale_y_continuous(labels = function(v) format(v, big.mark = ",", scientific = FALSE, trim = TRUE)) +
      labs(x = NULL, y = if (input$e1r_ds == "electricity") "kW" else "occupancy", subtitle = "blue = raw 80% interval · orange dashed = after CQR · black = observed (largest series)")
  })
  output$b_out <- renderUI({
    B <- (0.8 + input$b_d * input$b_g) / (input$b_T * input$b_g)
    ok <- B < 1
    withMathJax(div(class = paste("step", if (ok) "ok-box" else "bad-box"),
        p(sprintf("$$B = \\frac{\\max(\\alpha,1-\\alpha) + \\delta\\gamma}{T\\gamma} = %.2f$$", B)),
        strong(if (ok) "Informative: long-run miscoverage is guaranteed to be within B of 0.20." else "Vacuous: B ≥ 1 guarantees nothing.")))
  })

  # ------------------------------------------------------------ ext 2 distributions
  output$d_dist <- renderPlot({
    mu <- input$d_mu; u <- as.numeric(input$d_u); a <- input$d_a; pz <- input$d_pi; sg <- input$d_sigma
    kmax <- ceiling(max(mu * u * 4 + 10, 10)); k <- 0:kmax
    r <- 1 / a; nb <- dnbinom(k, size = r, mu = mu * u)
    lam <- mu * u / max(1 - pz, 1e-6); zip <- (1 - pz) * dpois(k, lam); zip[1] <- zip[1] + pz
    x <- seq(-max(3 * sg, 0.5), max(k / u), length.out = 400)
    gd <- dnorm(x, mu, sg)
    sc <- max(c(nb, zip)) / max(gd)
    qn <- function(p) qnorm(p, mu, sg)
    qnb <- qnbinom(c(.1, .5, .9), size = r, mu = mu * u) / u
    qz <- sapply(c(.1, .5, .9), function(q) { qa <- (q - pz) / (1 - pz); if (qa <= 0) 0 else qpois(qa, lam) }) / u
    pneg <- pnorm(0, mu, sg)
    width <- 0.38 / u
    ggplot() +
      geom_area(aes(x[x <= 0], gd[x <= 0] * sc), fill = COL[["red"]], alpha = 0.4) +
      geom_line(aes(x, gd * sc, colour = "Gaussian"), linewidth = 1.1) +
      geom_col(aes(k / u - width / 2, nb, fill = "Negative binomial"), width = width, alpha = 0.85) +
      geom_col(aes(k / u + width / 2, zip, fill = "Zero-inflated Poisson"), width = width, alpha = 0.85) +
      geom_point(aes(qn(c(.1, .5, .9)), -0.03 * max(nb, zip), colour = "Gaussian"), shape = 17, size = 3) +
      geom_point(aes(qnb, -0.07 * max(nb, zip)), colour = COL[["pink"]], shape = 17, size = 3) +
      geom_point(aes(qz, -0.11 * max(nb, zip)), colour = COL[["yellow"]], shape = 17, size = 3) +
      scale_fill_manual(values = c("Negative binomial" = COL[["pink"]], "Zero-inflated Poisson" = COL[["yellow"]]), name = NULL) +
      scale_colour_manual(values = c(Gaussian = COL[["blue"]]), name = NULL) +
      coord_cartesian(xlim = c(min(x), min(max(k / u), mu + 5 * sg + 1))) +
      labs(x = "tomorrow's value y", y = "probability",
           subtitle = sprintf("Gaussian puts %.1f%% of its mass below zero · ▲ = 10/50/90%% quantiles", 100 * pneg))
  })
  output$d_trap <- renderPlot({
    mu <- input$d_mu; u <- c(1, 2, 5, 10, 20, 50, 100, 200)
    d <- data.frame(u = u, sd = sqrt(mu / u))
    ggplot(d, aes(u, sd)) + geom_line(linewidth = 1.2, colour = COL[["yellow"]]) + geom_point(size = 2.5, colour = COL[["yellow"]]) +
      geom_point(data = data.frame(u = as.numeric(input$d_u), sd = sqrt(mu / as.numeric(input$d_u))), size = 6, colour = COL[["orange"]]) +
      scale_x_log10(breaks = u) + labs(x = "count resolution u (log scale)", y = "Poisson spread of y",
                                       subtitle = sprintf("sd(y) = √(μ/u); our traffic runs use u = 100"))
  })
  output$d_res <- renderPlot({
    cols <- c("QL50", "QL90", "NRMSE", "SMAPE", "MASE"); b <- ext2[ext2$model == "DeepTCN-quantile", cols]
    d <- do.call(rbind, lapply(c("DeepTCN-negbin", "DeepTCN-zip"), function(m) {
      v <- ext2[ext2$model == m, cols]; data.frame(metric = cols, change = 100 * (unlist(v) - unlist(b)) / unlist(b),
                                                   head = ifelse(m == "DeepTCN-negbin", "Negative binomial", "Zero-inflated Poisson"))
    }))
    d$metric <- factor(d$metric, levels = cols)
    ggplot(d, aes(metric, change, fill = head)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -3, ymax = 3, fill = "#1b2640") +
      geom_col(position = position_dodge(0.8), width = 0.75) + geom_hline(yintercept = 0) +
      scale_fill_manual(values = c("Negative binomial" = COL[["pink"]], "Zero-inflated Poisson" = COL[["yellow"]]), name = NULL) +
      labs(x = NULL, y = "% change vs quantile head", subtitle = "above 0 = worse · grey = ±3% noise band")
  })

  # ------------------------------------------------------------ ext 3 memory
  g_s <- reactive({ s0 <- 16.8; s0 * (1 / s0)^input$g_prog })
  output$g_s_txt <- renderUI(how_to(sprintf("Sharpness s = %.1f. Early in training the mask is soft (so τ gets gradients); later it becomes a sharp cut. Press play on 'training progress'.", g_s())))
  g_series <- reactive({
    set.seed(9); l <- 0:167
    y <- rev(2 + sin(2 * pi * (0:167) / 24) + rnorm(168, 0, 0.2))
    if (input$g_pad) y[l >= 40] <- 0
    m <- sigmoid((input$g_tau - l) / g_s())
    data.frame(age = l, y = y, m = m)
  })
  output$g_mask <- renderPlot({
    d <- g_series()
    ggplot(d, aes(age, m)) + geom_area(fill = COL[["orange"]], alpha = 0.25) + geom_line(colour = COL[["orange"]], linewidth = 1.3) +
      geom_vline(xintercept = input$g_tau, linetype = 2) +
      annotate("label", x = input$g_tau, y = 1.06, label = sprintf("τ = %d h", input$g_tau), size = 3.8) +
      scale_x_reverse() + coord_cartesian(ylim = c(0, 1.1)) +
      labs(x = "age of the hour (0 = newest, right)", y = "mask m(l)")
  })
  output$g_input <- renderPlot({
    d <- g_series()
    ggplot(d, aes(age)) + geom_area(aes(y = m * max(d$y)), fill = COL[["orange"]], alpha = 0.18) +
      geom_line(aes(y = y), colour = "#64748b", linewidth = 0.7) + geom_line(aes(y = y * m), colour = COL[["blue"]], linewidth = 1.1) +
      scale_x_reverse() + labs(x = "age of the hour (0 = newest, right)", y = "value",
                               subtitle = if (input$g_pad) "padded zeros older than 40 h: a short τ hides them" else "full history")
  })
  output$g_res <- renderPlot({
    r <- ext34[ext34$row %in% c("tau", "both"), ]
    d <- data.frame(row = c("+ memory", "+ both"), med = r$tau_median, lo = r$tau_min, hi = r$tau_max)
    ggplot(d, aes(med, row)) + geom_vline(xintercept = c(168, 232), linetype = c(3, 2), colour = c(MUTED, COL[["orange"]])) +
      geom_segment(aes(x = lo, xend = hi, yend = row), colour = COL[["blue"]], linewidth = 1.2) +
      geom_point(size = 4, colour = COL[["blue"]]) +
      annotate("text", x = 170, y = 2.45, label = "window L = 168 h", hjust = 0, size = 3.6) +
      annotate("text", x = 230, y = 0.55, label = "fully open (232 h)", hjust = 1, size = 3.6, colour = COL[["orange"]]) +
      coord_cartesian(xlim = c(0, 240)) + labs(x = "learned memory length τ (hours) across 320 lanes", y = NULL)
  })

  # ------------------------------------------------------------ theory: interval score in motion
  output$w_plot <- renderPlot({
    y <- input$w_y; lo <- -1; hi <- 1; a <- 0.2
    pen <- (2 / a) * max(lo - y, 0) + (2 / a) * max(y - hi, 0)
    grid <- seq(-3, 3, length.out = 300)
    sc <- (hi - lo) + (2 / a) * pmax(lo - grid, 0) + (2 / a) * pmax(grid - hi, 0)
    inside <- y >= lo && y <= hi
    ggplot() +
      annotate("rect", xmin = lo, xmax = hi, ymin = -Inf, ymax = Inf, fill = COL[["green"]], alpha = 0.12) +
      geom_line(aes(grid, sc), colour = COL[["blue"]], linewidth = 1.3) +
      geom_segment(aes(x = y, xend = y, y = 0, yend = (hi - lo) + pen),
                   colour = if (inside) COL[["green"]] else COL[["orange"]], linewidth = 1.6) +
      geom_point(aes(y, (hi - lo) + pen), colour = COL[["yellow"]], size = 4.5) +
      annotate("text", x = 0, y = 26, label = "80% interval", colour = COL[["green"]], size = 4.2) +
      coord_cartesian(ylim = c(0, 28)) +
      labs(x = "true value y (interval = [-1, 1])", y = "Winkler score",
           subtitle = sprintf("score = width 2.0 + penalty %.1f = %.1f  (%s)", pen, 2 + pen, if (inside) "covered" else "missed"))
  })

  # ------------------------------------------------------------ ext 4 attention
  output$t_lane_ui <- renderUI(sliderInput("t_lane", "Focus on lane", 1, input$t_n, min(3, input$t_n), step = 1))
  att <- reactive({
    input$t_go; set.seed(40 + input$t_go)
    N <- input$t_n; G <- input$t_groups; dE <- 8
    grp <- sort(rep_len(1:G, N))
    centers <- matrix(rnorm(G * dE, 0, 1.5), G, dE)
    E <- centers[grp, , drop = FALSE] + matrix(rnorm(N * dE, 0, input$t_noise), N, dE)
    S <- E %*% t(E) / sqrt(dE)
    if (input$t_diag) diag(S) <- -Inf
    A <- exp(S - apply(S, 1, max)); A <- A / rowSums(A)
    tt <- 0:47; fac <- sapply(1:G, function(g) sin(2 * pi * (tt + 4 * g) / 24) * (0.6 + 0.2 * g))
    Y <- t(sapply(1:N, function(i) 2 + fac[, grp[i]] + rnorm(48, 0, 0.35)))
    list(A = A, grp = grp, Y = Y, N = N)
  })
  output$t_heat <- renderPlot({
    a <- att(); N <- a$N
    d <- expand.grid(to = 1:N, from = 1:N); d$w <- as.vector(t(a$A))
    ggplot(d, aes(to, from, fill = w)) + geom_tile() +
      scale_fill_gradient(low = "#0f172a", high = COL[["blue"]], name = "weight") +
      scale_y_reverse() + coord_equal() + labs(x = "attends to lane", y = "lane") +
      theme(panel.grid = element_blank(), legend.position = "right")
  }, bg = CARD)
  output$t_mix <- renderPlot({
    a <- att(); i <- if (is.null(input$t_lane)) 1 else min(input$t_lane, a$N)
    own <- a$Y[i, ]; nb <- as.vector(a$A[i, ] %*% a$Y); mixed <- own + input$t_alpha * (nb - mean(nb))
    d <- data.frame(h = rep(0:47, 3), v = c(own, nb, mixed),
                    s = rep(c("own summary h", "neighbours A·h", "result h + α·A·h"), each = 48))
    top <- order(a$A[i, ], decreasing = TRUE)[1:3]
    ggplot(d, aes(h, v, colour = s, linewidth = s)) + geom_line() +
      scale_colour_manual(values = c("own summary h" = MUTED, "neighbours A·h" = COL[["green"]], "result h + α·A·h" = COL[["orange"]]), name = NULL) +
      scale_linewidth_manual(values = c(0.8, 1.4, 0.9), guide = "none") +
      labs(x = "hour", y = "signal", subtitle = sprintf("lane %d (group %d) · top neighbours: %s", i, a$grp[i], paste(top, collapse = ", ")))
  })
  output$t_perm <- renderPlot({
    a <- att(); Y <- a$Y - rowMeans(a$Y); C <- suppressWarnings(cor(t(Y))); diag(C) <- 0; C[!is.finite(C)] <- 0
    A <- a$A; A[!is.finite(A)] <- 0; N <- a$N
    obs <- sum(A * C) / N
    set.seed(1); null <- replicate(200, { p <- sample(N); sum(A[p, p] * C) / N })
    pv <- mean(null >= obs)
    ggplot(data.frame(null = null), aes(null)) + geom_histogram(bins = 30, fill = "#334155") +
      geom_vline(xintercept = obs, colour = COL[["orange"]], linewidth = 1.4) +
      labs(x = "coherence  Σ A·C / N", y = "shuffled embeddings",
           subtitle = sprintf("observed %.3f · p = %s", obs, if (pv == 0) "< 0.005" else fmt(pv, 3)))
  })
  output$t_res <- renderPlot({
    cols <- c("QL50", "QL90", "NRMSE", "SMAPE", "MASE"); b <- ext34[ext34$row == "baseline", cols]
    lab <- c(attn = "+ attention", tau = "+ memory", both = "+ both")
    d <- do.call(rbind, lapply(names(lab), function(r) {
      v <- ext34[ext34$row == r, cols]; data.frame(metric = cols, change = 100 * (unlist(v) - unlist(b)) / unlist(b), row = lab[[r]])
    }))
    d$metric <- factor(d$metric, levels = cols); d$row <- factor(d$row, levels = lab)
    ggplot(d, aes(metric, change, fill = row)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -3, ymax = 3, fill = "#1b2640") +
      geom_col(position = position_dodge(0.8), width = 0.75) + geom_hline(yintercept = 0) +
      scale_fill_manual(values = c(COL[["blue"]], COL[["green"]], COL[["orange"]]), name = NULL) +
      coord_cartesian(ylim = c(-6, 6)) + labs(x = NULL, y = "% change vs baseline", subtitle = "all changes inside the ±3% noise band")
  })
}

shinyApp(ui, server)
