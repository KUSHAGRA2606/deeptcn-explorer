"""
DeepTCN in motion: 3Blue1Brown-style animations of the paper and our four extensions.

Rendered with Manim Community Edition (the maintained fork of 3b1b's manim).
Formulas are typeset with matplotlib's TeX engine (mathtext) into vector SVGs, so no
LaTeX installation is needed.

    manim -r 1920,1080 --fps 30 deeptcn_scenes.py Intro
    manim -r 1920,1080 --fps 30 deeptcn_scenes.py      # pick from the list
"""
import hashlib
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from manim import *

# ----------------------------------------------------------------- palette
BG = "#0b1120"
C_BLUE = "#38bdf8"
C_ORANGE = "#fb923c"
C_GREEN = "#34d399"
C_VIOLET = "#a78bfa"
C_YELLOW = "#facc15"
C_PINK = "#f472b6"
C_RED = "#f87171"
C_GREY = "#94a3b8"
C_DIM = "#334155"
FONT = "Segoe UI"

config.background_color = BG

# ----------------------------------------------------------------- formulas without LaTeX
plt.rcParams["mathtext.fontset"] = "cm"
plt.rcParams["svg.fonttype"] = "path"
_TEX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_tex_svg")
os.makedirs(_TEX_DIR, exist_ok=True)


def Formula(expr, height=0.6, color=WHITE):
    """TeX-like formula as a vector mobject, typeset by matplotlib mathtext."""
    key = hashlib.md5(("v2" + expr).encode()).hexdigest()[:16]
    path = os.path.join(_TEX_DIR, key + ".svg")
    if not os.path.exists(path):
        fig = plt.figure(figsize=(0.01, 0.01))
        fig.patch.set_visible(False)          # no background box in the SVG
        fig.text(0, 0, expr, fontsize=40, color="white")
        fig.savefig(path, transparent=True, bbox_inches="tight", pad_inches=0.02)
        plt.close(fig)
    m = SVGMobject(path)
    m.set_fill(color, opacity=1).set_stroke(width=0)
    m.height = height
    return m


def T(text, size=32, color=WHITE, weight=NORMAL):
    return Text(text, font=FONT, font_size=size, color=color, weight=weight)


def title_card(scene, text, sub=None):
    t = T(text, 46, WHITE, BOLD).to_edge(UP, buff=0.45)
    line = Line(LEFT, RIGHT, color=C_BLUE, stroke_width=3).set_width(t.width + 0.6).next_to(t, DOWN, 0.15)
    grp = VGroup(t, line)
    if sub:
        s = T(sub, 24, C_GREY).next_to(line, DOWN, 0.2)
        grp.add(s)
    scene.play(Write(t), GrowFromCenter(line), run_time=1.2)
    if sub:
        scene.play(FadeIn(grp[-1], shift=0.2 * DOWN), run_time=0.6)
    return grp


def series_curve(axes, f, color, width=3):
    return axes.plot(f, color=color, stroke_width=width)


# =================================================================== 1. intro
class Intro(Scene):
    def construct(self):
        title = T("DeepTCN", 96, WHITE, BOLD)
        sub = T("Probabilistic forecasting with temporal convolutional networks", 30, C_GREY)
        VGroup(title, sub).arrange(DOWN, buff=0.35)
        self.play(Write(title), run_time=1.5)
        self.play(FadeIn(sub, shift=0.2 * UP))
        self.wait(0.8)
        self.play(title.animate.scale(0.55).to_edge(UP, buff=0.3),
                  sub.animate.scale(0.8).to_edge(UP, buff=1.05))

        # many related series
        ax = Axes(x_range=[0, 12, 1], y_range=[-1, 8, 1], x_length=6.0, y_length=4.6,
                  axis_config={"stroke_color": C_DIM, "include_ticks": False}).to_edge(LEFT, buff=0.6).shift(0.4 * DOWN)
        rng = np.random.default_rng(3)
        cols = [C_BLUE, C_VIOLET, C_GREEN, C_ORANGE, C_PINK, C_YELLOW, C_BLUE, C_VIOLET]
        curves = VGroup()
        for i in range(8):
            lvl, ph, a = 0.4 + i * 0.85, rng.uniform(0, 2), rng.uniform(0.25, 0.45)
            curves.add(series_curve(ax, lambda x, lvl=lvl, ph=ph, a=a: lvl + a * np.sin(2 * np.pi * x / 4 + ph)
                                    + 0.12 * np.sin(5.1 * x + ph), cols[i], 2.5))
        lab = T("963 traffic lanes · 370 electricity customers", 24, C_GREY).next_to(ax, DOWN, 0.25)
        self.play(LaggedStart(*[Create(c) for c in curves], lag_ratio=0.15), run_time=3)
        self.play(FadeIn(lab))

        # one shared network
        net = RoundedRectangle(corner_radius=0.25, width=2.6, height=1.7, color=C_BLUE, fill_opacity=0.15)
        net_t = T("one shared\nnetwork", 30, WHITE, BOLD).move_to(net)
        netg = VGroup(net, net_t).move_to(RIGHT * 1.2 + 0.3 * DOWN)
        arrows = VGroup(*[Arrow(c.get_end(), net.get_left(), buff=0.15, stroke_width=2, color=c.get_color(),
                                max_tip_length_to_length_ratio=0.06) for c in curves])
        self.play(FadeIn(netg, scale=0.8), LaggedStart(*[GrowArrow(a) for a in arrows], lag_ratio=0.08), run_time=2)

        # fan of quantiles out
        fan_ax = Axes(x_range=[0, 6, 1], y_range=[0, 4, 1], x_length=3.2, y_length=2.6,
                      axis_config={"stroke_color": C_DIM, "include_ticks": False}).next_to(netg, RIGHT, 0.7)
        mid = fan_ax.plot(lambda x: 2 + 0.6 * np.sin(x), color=C_YELLOW, stroke_width=4)
        band = fan_ax.get_area(fan_ax.plot(lambda x: 2 + 0.6 * np.sin(x) + 0.25 + 0.18 * x),
                               bounded_graph=fan_ax.plot(lambda x: 2 + 0.6 * np.sin(x) - 0.25 - 0.18 * x),
                               color=C_ORANGE, opacity=0.35)
        out_arrow = Arrow(net.get_right(), fan_ax.get_left(), buff=0.1, color=C_ORANGE)
        q = T("next 24 hours as a range\n(10%, 50%, 90%)", 22, C_ORANGE).next_to(fan_ax, DOWN, 0.2)
        self.play(GrowArrow(out_arrow), FadeIn(band), Create(mid), run_time=1.5)
        self.play(FadeIn(q))
        self.wait(2)


# =================================================================== 2. window
class ForecastWindow(Scene):
    def construct(self):
        title_card(self, "What exactly is forecast?", "look back 168 hours · predict 24 hours · give a range")
        ax = Axes(x_range=[0, 220, 24], y_range=[0, 5, 1], x_length=12, y_length=3.6,
                  axis_config={"stroke_color": C_DIM, "include_ticks": False}).shift(0.7 * DOWN)
        rng = np.random.default_rng(1)
        noise = rng.normal(0, 0.12, 400)
        f = lambda x: 2.4 + 1.3 * np.sin(2 * np.pi * x / 24) + 0.4 * np.sin(2 * np.pi * x / 168) + noise[int(x) % 400]
        past = ax.plot(f, x_range=[0, 190, 0.5], color=C_GREY, stroke_width=2.5)
        self.play(Create(past), run_time=2.5)

        t0 = ValueTracker(150)
        hist = always_redraw(lambda: Rectangle(
            width=ax.x_axis.unit_size * 168 * 0.62, height=3.6, stroke_width=0, fill_color=C_BLUE, fill_opacity=0.14
        ).move_to(ax.c2p(t0.get_value() - 168 * 0.31, 2.5)))
        # x-unit is scaled: show a 168h window proportionally on a compressed axis
        hist_lab = always_redraw(lambda: T("history: 168 h", 22, C_BLUE).next_to(hist, UP, 0.1))
        tline = always_redraw(lambda: DashedLine(ax.c2p(t0.get_value(), 0), ax.c2p(t0.get_value(), 5), color=WHITE))
        tlab = always_redraw(lambda: Formula(r"$t$", 0.3).next_to(tline, DOWN, 0.1))
        self.play(FadeIn(hist), FadeIn(hist_lab), Create(tline), FadeIn(tlab))

        def fan():
            x0 = t0.get_value()
            mid = ax.plot(lambda x: f(x) * 0 + 2.4 + 1.3 * np.sin(2 * np.pi * x / 24) + 0.4 * np.sin(2 * np.pi * x / 168),
                          x_range=[x0, x0 + 24, 0.5], color=C_YELLOW, stroke_width=4)
            up = ax.plot(lambda x: 2.4 + 1.3 * np.sin(2 * np.pi * x / 24) + 0.4 * np.sin(2 * np.pi * x / 168) + 0.25 + 0.02 * (x - x0),
                         x_range=[x0, x0 + 24, 0.5])
            lo = ax.plot(lambda x: 2.4 + 1.3 * np.sin(2 * np.pi * x / 24) + 0.4 * np.sin(2 * np.pi * x / 168) - 0.25 - 0.02 * (x - x0),
                         x_range=[x0, x0 + 24, 0.5])
            band = ax.get_area(up, bounded_graph=lo, x_range=[x0, x0 + 24], color=C_ORANGE, opacity=0.4)
            return VGroup(band, mid)
        fan_m = always_redraw(fan)
        self.play(FadeIn(fan_m), run_time=1)
        flab = T("24 h ahead:\n10% · 50% · 90%", 20, C_ORANGE).next_to(ax.c2p(175, 4.6), RIGHT, 0.1)
        self.play(FadeIn(flab))
        self.play(t0.animate.set_value(166), run_time=3, rate_func=smooth)
        self.play(FadeOut(flab))

        eq = Formula(r"$P\left(y_{t+1:t+24}\ \mid\ y_{1:t},\ X\right)$", 0.7).to_edge(DOWN, buff=0.35)
        box = SurroundingRectangle(eq, color=C_BLUE, buff=0.18, corner_radius=0.12)
        self.play(Write(eq), Create(box))
        note = T("the whole future window, for every series, conditioned on the past and known calendar X", 22, C_GREY)\
            .next_to(box, UP, 0.15)
        self.play(FadeIn(note))
        self.wait(2)


# =================================================================== 3. dilated convolutions
class DilatedConvolution(Scene):
    def construct(self):
        title_card(self, "Dilated causal convolutions", "look only at the past · double the reach at every layer")
        n_t, dils, K = 16, [1, 2, 4, 8], 2
        x0, dx, y0, dy = -5.9, 0.6, -2.7, 1.1
        pos = lambda t, l: np.array([x0 + t * dx, y0 + l * dy, 0])
        dots = VGroup(*[VGroup(*[Dot(pos(t, l), radius=0.07, color=C_DIM) for t in range(n_t)]) for l in range(len(dils) + 1)])
        labels = VGroup(T("input", 20, C_GREY).next_to(pos(0, 0), LEFT, 0.3),
                        *[T(f"d = {d}", 20, C_GREY).next_to(pos(0, l + 1), LEFT, 0.3) for l, d in enumerate(dils)])
        self.play(LaggedStart(*[FadeIn(r, lag_ratio=0.05) for r in dots], lag_ratio=0.2), FadeIn(labels), run_time=2)

        formula = Formula(r"$s(t)=\sum_{k=0}^{K-1} w(k)\,x(t-d\cdot k)$", 0.62).scale_to_fit_width(3.5)\
            .move_to(RIGHT * 5.1 + UP * 1.6)
        self.play(Write(formula))

        # trace the receptive field of the newest output
        active = {len(dils): {n_t - 1}}
        top = dots[len(dils)][n_t - 1]
        self.play(top.animate.set_color(C_YELLOW).scale(1.8), run_time=0.6)
        rf_val = ValueTracker(1)
        rf = always_redraw(lambda: VGroup(T("receptive field", 24, C_GREY),
                                          T(f"{int(rf_val.get_value())} steps", 36, C_YELLOW, BOLD)).arrange(DOWN, buff=0.1)
                           .next_to(formula, DOWN, 0.5))
        self.add(rf)
        for l in range(len(dils), 0, -1):
            d = dils[l - 1]
            new = set()
            edges = VGroup()
            for t in sorted(active[l]):
                for k in range(K):
                    s = t - d * k
                    if s >= 0:
                        new.add(s)
                        edges.add(Line(pos(s, l - 1), pos(t, l), color=C_ORANGE, stroke_width=2.5, stroke_opacity=0.8))
            active[l - 1] = new
            lit = VGroup(*[dots[l - 1][s] for s in sorted(new)])
            self.play(LaggedStart(*[Create(e) for e in edges], lag_ratio=0.05),
                      lit.animate.set_color(C_ORANGE), rf_val.animate.set_value(1 + (K - 1) * sum(dils[l - 1:])),
                      run_time=1.4)
        brace = Brace(VGroup(*[dots[0][s] for s in active[0]]), DOWN, color=C_YELLOW)
        btxt = T("only the past (causal)", 22, C_YELLOW).next_to(brace, DOWN, 0.1)
        self.play(GrowFromCenter(brace), FadeIn(btxt))
        self.wait(1)

        eq2 = Formula(r"$r = 1 + n(K-1)\sum_b d_b$", 0.5).next_to(rf, DOWN, 0.45)
        ours = T("ours: 6 blocks × 2 convs\nd = 1…32  →  r = 127 h", 22, C_GREEN).next_to(eq2, DOWN, 0.25)
        self.play(Write(eq2))
        self.play(FadeIn(ours, shift=0.2 * UP))
        self.wait(2.5)


# =================================================================== 4. encoder -> decoder
class EncoderDecoder(Scene):
    def construct(self):
        title_card(self, "Encoder → decoder: all 24 hours at once")
        hist = VGroup(*[Rectangle(width=0.18, height=0.25 + 0.5 * abs(np.sin(i / 2.2)), fill_color=C_GREY,
                                  fill_opacity=0.8, stroke_width=0) for i in range(14)]).arrange(RIGHT, buff=0.04, aligned_edge=DOWN)
        hist.move_to(LEFT * 5.4 + UP * 0.9)
        hl = T("history", 22, C_GREY).next_to(hist, UP, 0.15)
        enc = RoundedRectangle(corner_radius=0.2, width=2.2, height=1.3, color=C_BLUE, fill_opacity=0.15).next_to(hist, RIGHT, 0.6)
        enc_t = T("encoder\n(dilated TCN)", 22, WHITE).move_to(enc)
        self.play(LaggedStart(*[GrowFromEdge(b, DOWN) for b in hist], lag_ratio=0.05), FadeIn(hl))
        self.play(FadeIn(VGroup(enc, enc_t), shift=0.2 * RIGHT), GrowArrow(Arrow(hist.get_right(), enc.get_left(), buff=0.1, color=C_GREY)))

        h = VGroup(*[Square(0.28, fill_color=C_BLUE, fill_opacity=0.3 + 0.6 * ((i * 37) % 10) / 10, stroke_color=C_BLUE,
                            stroke_width=1.5) for i in range(5)]).arrange(DOWN, buff=0.04).next_to(enc, RIGHT, 0.7)
        hlab = Formula(r"$h_t$", 0.38, C_BLUE).next_to(h, UP, 0.15)
        self.play(GrowArrow(Arrow(enc.get_right(), h.get_left(), buff=0.1, color=C_BLUE)), FadeIn(h, lag_ratio=0.2), Write(hlab))

        # decoder slots
        slots = VGroup()
        for j in range(6):
            cal = RoundedRectangle(corner_radius=0.08, width=0.8, height=0.5, color=C_VIOLET, fill_opacity=0.15)
            ct = Formula(rf"$X_{{t+{j + 1 if j < 5 else 24}}}$", 0.26, C_VIOLET).move_to(cal)
            slots.add(VGroup(cal, ct))
        slots.arrange(RIGHT, buff=0.22).move_to(RIGHT * 3.2 + DOWN * 2.55)
        dots_t = T("…", 34, C_VIOLET).move_to((slots[4].get_center() + slots[5].get_center()) / 2)
        slots[5].shift(0.35 * RIGHT)
        cal_lab = T("known future calendar (hour, weekday, month)", 22, C_VIOLET).next_to(slots, DOWN, 0.2)
        self.play(LaggedStart(*[FadeIn(s, shift=0.2 * UP) for s in slots], lag_ratio=0.1), FadeIn(dots_t), FadeIn(cal_lab))

        dec = RoundedRectangle(corner_radius=0.2, width=slots.width + 0.8, height=0.7, color=C_VIOLET, fill_opacity=0.12)\
            .next_to(slots, UP, 0.35)
        dec_t = T("decoder R(·) shared by every horizon", 22, WHITE).move_to(dec)
        self.play(FadeIn(VGroup(dec, dec_t)))
        copies = VGroup(*[h.copy().scale(0.55).next_to(dec, UP, 0.35).set_x(s.get_x()) for s in slots])
        self.play(LaggedStart(*[TransformFromCopy(h, c) for c in copies], lag_ratio=0.08), run_time=1.6)

        outs = VGroup(*[VGroup(*[Dot(radius=0.06, color=c) for c in (C_ORANGE, C_YELLOW, C_ORANGE)]).arrange(UP, buff=0.08)
                        .next_to(c, UP, 0.25) for c in copies])
        self.play(LaggedStart(*[FadeIn(o, scale=1.6) for o in outs], lag_ratio=0.0), run_time=0.9)
        par = T("all 24 horizons\ndecoded in parallel", 28, C_YELLOW, BOLD).move_to(LEFT * 4.1 + DOWN * 1.5)
        self.play(Write(par))
        self.wait(1)

        eq = Formula(r"$\delta_{t+j} = R(X_{t+j}) + h_t,\qquad j=1,\dots,24$", 0.5).move_to(RIGHT * 3.3 + UP * 1.75)
        self.play(Write(eq))
        self.wait(1.5)

        # autoregressive vs direct: error accumulation
        self.play(*[FadeOut(m) for m in self.mobjects])
        title_card(self, "Why not feed predictions back in?")
        ax = Axes(x_range=[0, 24, 4], y_range=[0, 1.2, 0.4], x_length=9, y_length=4.2,
                  axis_config={"stroke_color": C_DIM}, tips=False).shift(0.6 * DOWN)
        xl = T("hours ahead", 22, C_GREY).next_to(ax, DOWN, 0.15)
        yl = T("error", 22, C_GREY).rotate(PI / 2).next_to(ax, LEFT, 0.15)
        self.play(Create(ax), FadeIn(xl), FadeIn(yl))
        ar = ax.plot(lambda h: 0.08 + 0.95 * (1 - np.exp(-h / 9)), x_range=[1, 24], color=C_GREY, stroke_width=5)
        dr = ax.plot(lambda h: 0.08 + 0.12 * np.sin(h / 24 * np.pi), x_range=[1, 24], color=C_BLUE, stroke_width=5)
        arl = T("autoregressive: errors compound", 24, C_GREY).next_to(ax.c2p(24, 1.0), LEFT, 0.1).shift(0.3 * UP)
        drl = T("DeepTCN (direct): errors stay small", 24, C_BLUE).next_to(ax.c2p(24, 0.25), LEFT, 0.1).shift(0.25 * UP)
        self.play(Create(ar), FadeIn(arl), run_time=2)
        self.play(Create(dr), FadeIn(drl), run_time=2)
        self.wait(2)


# =================================================================== 5. pinball loss
class PinballLoss(Scene):
    def construct(self):
        title_card(self, "Learning quantiles with the pinball loss")
        q = ValueTracker(0.5)
        ax = Axes(x_range=[-3, 3, 1], y_range=[0, 2.8, 1], x_length=5.4, y_length=3.6,
                  axis_config={"stroke_color": C_DIM}, tips=False).to_edge(LEFT, buff=0.7).shift(0.5 * DOWN)
        xl = Formula(r"$y-\hat{y}$", 0.32, C_GREY).next_to(ax.x_axis, DOWN, 0.2)
        loss = always_redraw(lambda: ax.plot(lambda u: max(q.get_value() * u, (q.get_value() - 1) * u),
                                             color=C_BLUE, stroke_width=5))
        eq = Formula(r"$L_q(y,\hat{y}) = q\,(y-\hat{y})_+ + (1-q)\,(\hat{y}-y)_+$", 0.5).next_to(ax, UP, 0.4).align_to(ax, LEFT)
        qlab = always_redraw(lambda: VGroup(Formula(r"$q=$", 0.42, C_YELLOW),
                                            T(f"{q.get_value():.2f}", 36, C_YELLOW, BOLD))
                             .arrange(RIGHT, buff=0.12).move_to(ax.c2p(0, 2.55)))
        self.play(Create(ax), FadeIn(xl), Write(eq))
        self.play(Create(loss), FadeIn(qlab))

        # sample from a skewed distribution and its expected loss
        rng = np.random.default_rng(4)
        y = rng.lognormal(0, 0.55, 600)
        ax2 = Axes(x_range=[0, 5, 1], y_range=[0, 1.4, 0.5], x_length=5.4, y_length=3.6,
                   axis_config={"stroke_color": C_DIM}, tips=False).to_edge(RIGHT, buff=0.7).shift(0.5 * DOWN)
        hist, edges = np.histogram(y, bins=30, range=(0, 5), density=True)
        bars = VGroup(*[Rectangle(width=ax2.x_axis.unit_size * (edges[1] - edges[0]) * 0.92, height=max(1e-3, ax2.y_axis.unit_size * hgt),
                                  fill_color=C_DIM, fill_opacity=0.9, stroke_width=0)
                        .move_to(ax2.c2p((edges[i] + edges[i + 1]) / 2, 0), aligned_edge=DOWN) for i, hgt in enumerate(hist)])
        grid = np.linspace(0.05, 4.95, 120)

        def risk_curve():
            qq = q.get_value()
            r = np.array([np.mean(np.maximum(qq * (y - g), (qq - 1) * (y - g))) for g in grid])
            pts = [ax2.c2p(g, v) for g, v in zip(grid, r)]
            return VMobject(color=C_YELLOW, stroke_width=4).set_points_smoothly(pts)

        def best_dot():
            qq = q.get_value()
            r = np.array([np.mean(np.maximum(qq * (y - g), (qq - 1) * (y - g))) for g in grid])
            i = int(np.argmin(r))
            return Dot(ax2.c2p(grid[i], r[i]), radius=0.11, color=C_GREEN)

        def true_q():
            v = np.quantile(y, q.get_value())
            return DashedLine(ax2.c2p(v, 0), ax2.c2p(v, 1.4), color=WHITE, stroke_width=2)

        rc, bd, tq = always_redraw(risk_curve), always_redraw(best_dot), always_redraw(true_q)
        lab2 = T("average loss over the data", 22, C_YELLOW).next_to(ax2, UP, 0.2)
        self.play(Create(ax2), LaggedStart(*[GrowFromEdge(b, DOWN) for b in bars], lag_ratio=0.02), run_time=1.5)
        self.play(Create(rc), FadeIn(lab2))
        self.play(FadeIn(bd), Create(tq))
        note = T("minimum (green) = true quantile (dashed)", 24, C_GREEN).next_to(ax2, DOWN, 0.3)
        self.play(FadeIn(note))
        for v in (0.9, 0.1, 0.5):
            self.play(q.animate.set_value(v), run_time=2.4, rate_func=smooth)
            self.wait(0.4)
        self.wait(1)


# =================================================================== 6. conformal calibration
class ConformalCalibration(Scene):
    def construct(self):
        title_card(self, "Extension 1 · Calibrating the intervals", "the raw 80% interval covered 89% on traffic: too wide")
        rng = np.random.default_rng(14)
        n = 40
        ax = Axes(x_range=[0, n, 5], y_range=[-3.2, 3.2, 1], x_length=7.5, y_length=4.2,
                  axis_config={"stroke_color": C_DIM, "include_ticks": False}, tips=False).to_edge(LEFT, buff=0.5).shift(0.6 * DOWN)
        ys = rng.normal(0, 1, n)
        w = ValueTracker(1.85)
        band = always_redraw(lambda: Polygon(ax.c2p(0, -w.get_value()), ax.c2p(n, -w.get_value()),
                                             ax.c2p(n, w.get_value()), ax.c2p(0, w.get_value()),
                                             stroke_width=0, fill_color=C_BLUE, fill_opacity=0.18))
        edges = always_redraw(lambda: VGroup(DashedLine(ax.c2p(0, w.get_value()), ax.c2p(n, w.get_value()), color=C_BLUE),
                                             DashedLine(ax.c2p(0, -w.get_value()), ax.c2p(n, -w.get_value()), color=C_BLUE)))
        dots = VGroup(*[Dot(ax.c2p(i + 0.5, v), radius=0.06) for i, v in enumerate(ys)])

        def recolor(m):
            for d, v in zip(m, ys):
                d.set_color(C_GREEN if abs(v) <= w.get_value() else C_RED)
        dots.add_updater(recolor)
        cov = always_redraw(lambda: VGroup(T("coverage", 24, C_GREY),
                                           T(f"{100 * np.mean(np.abs(ys) <= w.get_value()):.0f}%", 44, C_YELLOW, BOLD))
                            .arrange(DOWN, buff=0.1).move_to(RIGHT * 3.9 + UP * 1.35))
        self.play(Create(ax), FadeIn(band), Create(edges))
        self.play(LaggedStart(*[FadeIn(d, scale=1.5) for d in dots], lag_ratio=0.03), FadeIn(cov), run_time=2)
        self.add(dots)

        eq1 = Formula(r"$E = \max(\hat{q}_{0.1}-y,\ y-\hat{q}_{0.9})$", 0.46).next_to(cov, DOWN, 0.55).set_x(3.9)
        eq2 = Formula(r"$Q = E_{(k)},\quad k=\lceil(1-\alpha)(n+1)\rceil$", 0.4).next_to(eq1, DOWN, 0.35).set_x(3.9)
        self.play(Write(eq1))
        self.play(Write(eq2))
        cqr = T("CQR moves both edges by Q", 26, C_GREEN, BOLD).next_to(eq2, DOWN, 0.45).set_x(3.9)
        self.play(FadeIn(cqr))
        self.play(w.animate.set_value(1.28), run_time=2.5, rate_func=smooth)
        self.wait(0.6)
        res = T("traffic: 0.894 → 0.801,\nintervals 15% narrower", 24, C_GREEN).next_to(cqr, DOWN, 0.3).set_x(3.9)
        self.play(FadeIn(res, shift=0.2 * UP))
        self.wait(1.5)

        # ACI under shift
        self.play(*[FadeOut(m) for m in self.mobjects])
        title_card(self, "When the future shifts: ACI", "electricity test week starts on Christmas Day")
        ax = Axes(x_range=[0, 120, 20], y_range=[-0.25, 0.35, 0.1], x_length=10, y_length=3.6,
                  axis_config={"stroke_color": C_DIM}, tips=False).shift(0.5 * DOWN)
        ref = DashedLine(ax.c2p(0, 0.2), ax.c2p(120, 0.2), color=C_GREY)
        zero = DashedLine(ax.c2p(0, 0), ax.c2p(120, 0), color=C_DIM)
        lab = Formula(r"$\alpha_t$", 0.4, C_ORANGE).next_to(ax.y_axis, LEFT, 0.2)
        reft = T("target 0.20", 20, C_GREY).next_to(ref, RIGHT, 0.1)
        self.play(Create(ax), Create(ref), Create(zero), FadeIn(lab), FadeIn(reft))
        rng = np.random.default_rng(2)
        a, alphas = 0.2, []
        for t in range(120):
            p_miss = 0.75 if 20 <= t < 40 else (0.2 if t < 20 else 0.15)
            miss = rng.random() < p_miss
            alphas.append(a)
            a = a + 0.012 * (0.2 - miss)
        shade = Rectangle(width=ax.x_axis.unit_size * 20, height=3.6, fill_color=C_RED, fill_opacity=0.12, stroke_width=0)\
            .move_to(ax.c2p(30, 0.05))
        sh_t = T("shift: many misses", 20, C_RED).next_to(shade, UP, 0.05)
        path = VMobject(color=C_ORANGE, stroke_width=4).set_points_as_corners([ax.c2p(t, v) for t, v in enumerate(alphas)])
        eq = Formula(r"$\alpha_{t+1} = \alpha_t + \gamma\,(\alpha - \mathrm{err}_t)$", 0.55).to_edge(DOWN, buff=0.35)
        self.play(FadeIn(shade), FadeIn(sh_t), Write(eq))
        self.play(Create(path), run_time=5, rate_func=linear)
        note = T("misses push αₜ down → wider intervals → coverage recovers", 24, C_ORANGE).next_to(ax, DOWN, 0.2)
        self.play(FadeIn(note))
        self.wait(2)


# =================================================================== 7. count heads
class CountHeads(Scene):
    def construct(self):
        title_card(self, "Extension 2 · Count distributions", "occupancy can never be negative")
        ax = Axes(x_range=[-1, 3, 0.5], y_range=[0, 1.2, 0.4], x_length=10, y_length=4.2,
                  axis_config={"stroke_color": C_DIM}, tips=False).shift(0.6 * DOWN)
        self.play(Create(ax))
        mu, sd = 0.35, 0.4
        g = ax.plot(lambda x: np.exp(-(x - mu) ** 2 / (2 * sd ** 2)), color=C_BLUE, stroke_width=5)
        neg = ax.get_area(g, x_range=[-1, 0], color=C_RED, opacity=0.5)
        gl = T("Gaussian", 26, C_BLUE).next_to(ax.c2p(1.2, 1.0), RIGHT)
        self.play(Create(g), FadeIn(gl))
        nl = T("mass on impossible negative values", 24, C_RED).next_to(ax.c2p(-0.98, 1.12), RIGHT)
        self.play(FadeIn(neg), FadeIn(nl))
        self.wait(1)

        u = 10
        from math import lgamma, exp, log
        k = np.arange(0, 30)
        a = 0.6
        r = 1 / a
        m = mu * u
        nb = np.array([exp(lgamma(kk + r) - lgamma(kk + 1) - lgamma(r) + r * log(1 / (1 + a * m)) + kk * log(a * m / (1 + a * m))) for kk in k])
        pz, lam = 0.15, m / 0.85
        zp = np.array([(1 - pz) * exp(-lam + kk * log(lam) - lgamma(kk + 1)) for kk in k]); zp[0] += pz
        sc = 1.0 / max(nb.max(), zp.max())
        mk = lambda vals, col, off: VGroup(*[Rectangle(width=ax.x_axis.unit_size * 0.04, height=max(1e-3, ax.y_axis.unit_size * v * sc),
                                                       fill_color=col, fill_opacity=0.9, stroke_width=0)
                                             .move_to(ax.c2p(kk / u + off, 0), aligned_edge=DOWN) for kk, v in zip(k, vals)])
        nbb, zpb = mk(nb, C_PINK, -0.022), mk(zp, C_YELLOW, 0.022)
        nbl = T("negative binomial", 26, C_PINK).next_to(gl, DOWN, 0.2, aligned_edge=LEFT)
        zpl = T("zero-inflated Poisson", 26, C_YELLOW).next_to(nbl, DOWN, 0.2, aligned_edge=LEFT)
        self.play(LaggedStart(*[GrowFromEdge(b, DOWN) for b in nbb], lag_ratio=0.03), FadeIn(nbl), run_time=1.6)
        self.play(LaggedStart(*[GrowFromEdge(b, DOWN) for b in zpb], lag_ratio=0.03), FadeIn(zpl), run_time=1.6)
        eqs = VGroup(Formula(r"$\mathrm{NB}:\ \mathrm{Var} = \mu + a\mu^2$", 0.42),
                     Formula(r"$\mathrm{ZIP}:\ P(0) = \pi + (1-\pi)e^{-\lambda}$", 0.42)).arrange(DOWN, buff=0.2, aligned_edge=LEFT)\
            .next_to(zpl, DOWN, 0.4, aligned_edge=LEFT)
        self.play(Write(eqs))
        verdict = T("result: the quantile head still wins 4 of 5 metrics", 28, C_GREEN, BOLD).to_edge(DOWN, buff=0.3)
        self.play(FadeIn(verdict, shift=0.2 * UP))
        self.wait(2)


# =================================================================== 8. memory mask
class MemoryMask(Scene):
    def construct(self):
        title_card(self, "Extension 3 · Learning how far back to look", "a soft mask over the 168-hour window")
        L = 48
        bars_h = 0.4 + 0.9 * np.abs(np.sin(np.arange(L) / 3.0))
        tau, s = ValueTracker(30), ValueTracker(6)
        x0 = -5.6
        unit = 11.2 / L

        def mask(l):  # l = age, 0 = newest (right)
            return 1 / (1 + np.exp(-(tau.get_value() - l) / s.get_value()))

        def bars():
            g = VGroup()
            for i in range(L):
                age = L - 1 - i
                m = mask(age)
                g.add(Rectangle(width=unit * 0.75, height=bars_h[i], stroke_width=0, fill_color=C_BLUE,
                                fill_opacity=0.15 + 0.85 * m).move_to([x0 + i * unit, -2.35, 0], aligned_edge=DOWN))
            return g

        def curve():
            pts = [[x0 + i * unit, 0.25 + 1.45 * mask(L - 1 - i), 0] for i in np.linspace(0, L - 1, 200)]
            return VMobject(color=C_ORANGE, stroke_width=5).set_points_smoothly(pts)

        bars_m, curve_m = always_redraw(bars), always_redraw(curve)
        base = Line([x0 - 0.2, 0.25, 0], [x0 + L * unit, 0.25, 0], color=C_DIM)
        top = DashedLine([x0 - 0.2, 1.7, 0], [x0 + L * unit, 1.7, 0], color=C_DIM)
        ml = Formula(r"$m(l)$", 0.38, C_ORANGE).next_to(top, LEFT, 0.15)
        old = T("older", 22, C_GREY).next_to([x0, -2.4, 0], DOWN, 0.05)
        new = T("newest", 22, C_GREY).next_to([x0 + L * unit, -2.4, 0], DOWN, 0.05)
        self.play(FadeIn(bars_m), FadeIn(old), FadeIn(new))
        self.play(Create(base), Create(top), Create(curve_m), FadeIn(ml))
        eq = Formula(r"$m(l)=\sigma\left(\frac{\tau-l}{s}\right),\qquad \mathrm{input}=[\,y\odot m,\ m\,]$", 0.55)\
            .to_edge(DOWN, buff=0.3)
        self.play(Write(eq))
        tl = always_redraw(lambda: VGroup(Formula(r"$\tau=$", 0.4, C_YELLOW),
                                          T(f"{tau.get_value():.0f}", 36, C_YELLOW, BOLD))
                           .arrange(RIGHT, buff=0.1).move_to(LEFT * 4.6 + UP * 1.35))
        self.play(FadeIn(tl))
        self.play(tau.animate.set_value(10), run_time=2)
        self.play(tau.animate.set_value(44), run_time=2.5)
        ann = T("annealing: soft → sharp", 26, C_VIOLET, BOLD).move_to(LEFT * 4.2 + UP * 0.8)
        self.play(FadeIn(ann))
        self.play(s.animate.set_value(0.6), tau.animate.set_value(24), run_time=3)
        self.wait(0.6)
        res = T("on traffic every lane kept τ ≈ 230 h: full history is useful, so the gate stays open", 24, C_GREEN)\
            .move_to(DOWN * 0.45)
        self.play(s.animate.set_value(4), tau.animate.set_value(70), FadeIn(res), run_time=2.5)
        self.wait(2)


# =================================================================== 9. attention
class CrossSeriesAttention(Scene):
    def construct(self):
        title_card(self, "Extension 4 · Lanes that look at each other", "cross-series attention on the encoder summary")
        rng = np.random.default_rng(5)
        N, G = 12, 3
        grp = np.repeat(np.arange(G), N // G)
        cols = [C_BLUE, C_ORANGE, C_GREEN]
        ang = np.linspace(0, 2 * PI, N, endpoint=False) + PI / 2
        centre = LEFT * 3.6 + DOWN * 0.45
        pts = [centre + 2.05 * np.array([np.cos(a), np.sin(a), 0]) for a in ang]
        lanes = VGroup(*[Dot(p, radius=0.16, color=cols[g]) for p, g in zip(pts, grp)])
        self.play(LaggedStart(*[GrowFromCenter(d) for d in lanes], lag_ratio=0.06))

        E = np.array([[1, 0], [0, 1], [-1, -0.2]])[grp] * 2.2 + rng.normal(0, 0.45, (N, 2))
        S = E @ E.T / np.sqrt(2)
        np.fill_diagonal(S, -np.inf)
        A = np.exp(S - S.max(1, keepdims=True)); A /= A.sum(1, keepdims=True)

        i = 0
        arrows = VGroup(*[Arrow(pts[i], pts[k], buff=0.2, stroke_width=1 + 9 * A[i, k], color=C_YELLOW,
                                stroke_opacity=0.25 + 0.75 * A[i, k] / A[i].max(), max_tip_length_to_length_ratio=0.08)
                          for k in range(N) if k != i])
        self.play(Indicate(lanes[i], color=C_YELLOW, scale_factor=1.6))
        self.play(LaggedStart(*[GrowArrow(a) for a in arrows], lag_ratio=0.05), run_time=2)
        note = T("strong arrows\n→ its own group", 20, C_YELLOW).move_to(centre + DOWN * 0.35)
        self.play(FadeIn(note))
        self.wait(0.6)

        cell = 0.32
        mat = VGroup()
        for r in range(N):
            for c in range(N):
                v = 0 if r == c else A[r, c] / A.max()
                mat.add(Square(cell, stroke_width=0.5, stroke_color=BG, fill_color=interpolate_color(ManimColor("#0f172a"), ManimColor(C_BLUE), v),
                               fill_opacity=1).move_to(RIGHT * (2.3 + c * cell) + UP * (1.75 - r * cell)))
        mlab = Formula(r"$A$", 0.45).next_to(mat, UP, 0.15)
        self.play(LaggedStart(*[FadeIn(sq) for sq in mat], lag_ratio=0.004), Write(mlab), run_time=2)
        eq = Formula(r"$A=\mathrm{softmax}\left(\frac{EE^{\top}}{\sqrt{d}}\right),\qquad h \leftarrow h + \alpha\,(A\,h)$", 0.5)\
            .to_edge(DOWN, buff=0.35)
        self.play(Write(eq))
        res = T("real lanes: attention finds\nco-moving lanes (p < 0.005),\nbut accuracy does not improve", 20, C_GREEN)\
            .next_to(mat, DOWN, 0.25)
        self.play(FadeIn(res))
        self.wait(2.5)


# =================================================================== 10. results
class Results(Scene):
    def construct(self):
        title_card(self, "What we found")
        ax = Axes(x_range=[0, 4, 1], y_range=[0, 1, 0.2], x_length=5, y_length=3.8,
                  axis_config={"stroke_color": C_DIM}, tips=False).to_edge(LEFT, buff=0.8).shift(0.6 * DOWN)
        target = DashedLine(ax.c2p(0, 0.8), ax.c2p(4, 0.8), color=WHITE)
        tl = T("target 80%", 20, WHITE).next_to(ax.c2p(3.45, 0.8), UP, 0.08)
        vals = [(0.894, "raw", C_GREY), (0.801, "CQR", C_GREEN), (0.804, "ACI", C_ORANGE)]
        bars = VGroup()
        for i, (v, n, c) in enumerate(vals):
            b = Rectangle(width=0.9, height=ax.y_axis.unit_size * v, fill_color=c, fill_opacity=0.85, stroke_width=0)\
                .move_to(ax.c2p(i + 0.9, 0), aligned_edge=DOWN)
            bars.add(VGroup(b, T(n, 22, c).next_to(b, DOWN, 0.15), T(f"{v:.3f}", 22, WHITE).next_to(b, UP, 0.1)))
        cap = T("traffic: coverage of the 80% interval (dashed = 80% target)", 22, C_GREY).next_to(ax, UP, 0.3)
        self.play(Create(ax), FadeIn(cap))
        self.play(LaggedStart(*[GrowFromEdge(b[0], DOWN) for b in bars], lag_ratio=0.3),
                  LaggedStart(*[FadeIn(VGroup(b[1], b[2])) for b in bars], lag_ratio=0.3), run_time=2)
        self.play(Create(target))

        pts = VGroup(
            T("✓  DeepTCN replicates on traffic (QL50 0.068)", 26, WHITE),
            T("✓  calibration makes intervals trustworthy", 26, C_GREEN),
            T("✓  ACI handles the Christmas shift", 26, C_ORANGE),
            T("–  count heads, memory, attention: no gain", 26, C_GREY),
            T("   (but each behaves as theory predicts)", 22, C_GREY),
        ).arrange(DOWN, buff=0.3, aligned_edge=LEFT).to_edge(RIGHT, buff=0.6).shift(0.3 * DOWN)
        self.play(LaggedStart(*[FadeIn(p, shift=0.3 * LEFT) for p in pts], lag_ratio=0.4), run_time=3)
        self.wait(1)
        final = T("accurate medians ≠ trustworthy intervals", 34, C_YELLOW, BOLD).to_edge(DOWN, buff=0.35)
        self.play(Write(final))
        self.wait(2.5)


SCENES = ["Intro", "ForecastWindow", "DilatedConvolution", "EncoderDecoder", "PinballLoss",
          "ConformalCalibration", "CountHeads", "MemoryMask", "CrossSeriesAttention", "Results"]
