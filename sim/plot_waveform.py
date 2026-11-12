"""Trace le chronogramme a partir du CSV produit par ModelSim."""

import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

ROOT = Path(__file__).resolve().parents[1]
with (ROOT / "build/modelsim/pipeline.csv").open(newline="", encoding="ascii") as trace:
    samples = list(csv.DictReader(trace))

times = [int(row["time_ns"]) for row in samples]
period = times[1] - times[0]
inputs = [(t, int(row["input_hex"], 16)) for t, row in zip(times, samples) if row["start"] == "1"]
outputs = [(t, int(row["result"])) for t, row in zip(times, samples) if row["done"] == "1"]

ink, subtle = "#172a3e", "#516278"
blue, teal = "#075d92", "#007f74"
blue_fill, teal_fill = "#d9eefb", "#d9f3eb"
fig, (wave, table) = plt.subplots(
    2, 1, figsize=(12.5, 5.6), dpi=145, gridspec_kw={"height_ratios": [4.1, 1.05]}
)
fig.subplots_adjust(left=0.095, right=0.975, top=0.82, bottom=0.08, hspace=0.55)
fig.text(0.095, 0.94, "Racine carrée entière sur FPGA", fontsize=20, weight="bold", color=ink)
fig.text(0.095, 0.886, "Simulation ModelSim du pipeline VHDL", fontsize=11, color=subtle)

end = times[-1] + period // 2
half = period // 2
clock_edges = list(range(0, end + 1, half))
wave.step(clock_edges, [4.03 + 0.34 * (i % 2) for i in range(len(clock_edges))],
          where="post", lw=1.15, color=subtle)

start_levels = [int(row["start"]) for row in samples]
done_levels = [int(row["done"]) for row in samples]
wave.step([0, *(t - half for t in times), end], [3.03, *(3.03 + 0.34 * v for v in start_levels), 3.03],
          where="post", lw=1.45, color=blue)
wave.step([0, *times, end], [1.03, *(1.03 + 0.34 * v for v in done_levels), 1.03],
          where="post", lw=1.45, color=teal)

for data, y, offset, color, fill in (
    (inputs, 2.15, -half, blue, blue_fill),
    (outputs, 0.15, 0, teal, teal_fill),
):
    for index, (t, _) in enumerate(data, 1):
        left = t + offset
        wave.add_patch(Rectangle((left + 0.45, y), period - 0.9, 0.32,
                                 facecolor=fill, edgecolor=color, linewidth=0.65, zorder=3))
        wave.text(left + half, y + 0.16, str(index), ha="center", va="center",
                  fontsize=8.5, color=color, zorder=4)

highlight = next(i for i, (_, value) in enumerate(inputs) if value == 100)
accept_time, _ = inputs[highlight]
result_time, _ = outputs[highlight]
latency = (result_time - accept_time) // period
wave.plot([accept_time, accept_time], [1.72, 2.48], linestyle=":", color=blue, lw=1.2)
wave.plot([result_time, result_time], [0.48, 1.72], linestyle=":", color=teal, lw=1.2)
wave.annotate("", xy=(result_time, 1.72), xytext=(accept_time, 1.72),
              arrowprops={"arrowstyle": "<->", "color": ink, "lw": 1.15})
wave.text((accept_time + result_time) / 2, 1.85,
          f"{latency} périodes d’horloge · {result_time - accept_time} ns",
          ha="center", va="bottom", fontsize=10.2, weight="bold", color=ink)

wave.set_xlim(0, end)
wave.set_ylim(-0.05, 4.57)
wave.set_xticks(range(0, end + 1, 100))
wave.set_xticks(range(0, end + 1, period), minor=True)
wave.set_xlabel("Temps de simulation (ns)", fontsize=10, color=subtle)
wave.set_yticks([4.2, 3.2, 2.31, 1.2, 0.31], ["clk", "start", "A", "done", "Result"])
wave.tick_params(axis="both", which="both", length=0, pad=8, labelcolor=ink)
wave.set_axisbelow(True)
wave.grid(axis="x", which="major", color="#d6e0e9")
wave.grid(axis="x", which="minor", color="#eff3f7", linewidth=0.7)
for edge in wave.spines.values():
    edge.set_visible(False)

table.axis("off")
table.set_xlim(-1.05, len(inputs))
table.set_ylim(-0.6, 2.5)
table.text(-0.18, 2.0, "Entrée n°", ha="right", va="center", fontsize=9, color=subtle)
table.text(-0.18, 1.0, "A", ha="right", va="center", fontsize=9, color=blue)
table.text(-0.18, 0.0, "Result", ha="right", va="center", fontsize=9, color=teal)
for index, ((_, value), (_, result)) in enumerate(zip(inputs, outputs)):
    fill = "#edf3f8" if index != highlight else "#dceaf6"
    table.add_patch(Rectangle((index + 0.04, -0.51), 0.92, 3.0, facecolor=fill, edgecolor="none"))
    for y, label, color in ((2.0, index + 1, subtle), (1.0, value, blue), (0.0, result, teal)):
        table.text(index + 0.5, y, f"{label:,}".replace(",", " "), ha="center", va="center",
                   fontsize=8.5, weight="bold" if index == highlight else "normal", color=color)

fig.savefig(ROOT / "assets/chronogramme-pipeline.png", facecolor="white")
