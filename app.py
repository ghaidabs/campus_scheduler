"""
app.py -- Flask Web Server for INSAT Campus Scheduler

Architecture (following the pyswip tutorial pattern):
  Browser (HTML/CSS/JS)  ──HTTP──▶  Flask (Python)  ──pyswip──▶  SWI-Prolog

Endpoints:
  GET /                       → serves the HTML frontend
  GET /api/schedule           → quick schedule (first DFS hit)
  GET /api/schedule/optimal   → best-of-200 optimised schedule
"""

import os
import time
from flask import Flask, render_template, jsonify
from pyswip import Prolog

# ---------------------------------------------------------------------------
#  Boot
# ---------------------------------------------------------------------------

app = Flask(__name__)

prolog = Prolog()

# Point Prolog's working directory at the project root so that
# bridge.pl's  :- [main].  resolves the sibling .pl files correctly.
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
list(prolog.query(f"working_directory(_, '{PROJECT_DIR}')"))
prolog.consult(f"{PROJECT_DIR}/bridge.pl")


# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------

PERIOD_TIMES = {
    1: "08:00 – 09:30",
    2: "09:30 – 11:00",
    3: "11:00 – 12:30",
    5: "14:00 – 15:30",
    6: "15:30 – 17:00",
    7: "17:00 – 18:30",
}

COURSE_NAMES = {
    "c_algo_cm":        "Algorithmique",
    "c_algo_tp_a":      "Algorithmique",
    "c_algo_tp_b":      "Algorithmique",
    "c_analyse_cm":     "Analyse Mathématique",
    "c_analyse_td_a":   "Analyse Mathématique",
    "c_analyse_td_b":   "Analyse Mathématique",
    "c_algebre_cm":     "Algèbre Linéaire",
    "c_algebre_td_a":   "Algèbre Linéaire",
    "c_algebre_td_b":   "Algèbre Linéaire",
    "c_chimie_cm":      "Chimie Générale",
    "c_chimie_tp_a":    "Chimie Générale",
    "c_chimie_tp_b":    "Chimie Générale",
    "c_bio_cm":         "Biologie Cellulaire",
    "c_bio_tp_a":       "Biologie Cellulaire",
    "c_bio_tp_b":       "Biologie Cellulaire",
    "c_maths_cba_cm":   "Mathématiques",
    "c_maths_cba_td_a": "Mathématiques",
    "c_maths_cba_td_b": "Mathématiques",
}

DAY_ORDER = ["monday", "tuesday", "wednesday", "thursday", "friday"]


def to_str(val):
    """Normalise a pyswip atom into a plain Python string."""
    if isinstance(val, bytes):
        return val.decode("utf-8")
    return str(val)


def session_type(course_id: str) -> str:
    if "_cm" in course_id:
        return "CM"
    if "_tp_" in course_id:
        return "TP"
    if "_td_" in course_id:
        return "TD"
    return "CM"


def subgroup(course_id: str):
    if course_id.endswith("_a"):
        return "A"
    if course_id.endswith("_b"):
        return "B"
    return None


def base_course(course_id: str) -> str:
    """Extract the base subject name for colour-grouping."""
    for key in ("algo", "analyse", "algebre", "chimie", "bio", "maths_cba"):
        if key in course_id:
            return key
    return "other"


# ---------------------------------------------------------------------------
#  Build JSON response from cached Prolog schedule
# ---------------------------------------------------------------------------

def build_response(elapsed: float):
    entries = list(prolog.query(
        "get_entry(Course, Session, Room, Day, Period, Track)"
    ))

    if not entries:
        return jsonify({"error": "No valid schedule found."}), 404

    mpi, cba = [], []

    for e in entries:
        cid   = to_str(e["Course"])
        room  = to_str(e["Room"])
        day   = to_str(e["Day"])
        period = int(e["Period"])
        track  = to_str(e["Track"])

        row = {
            "course_id":    cid,
            "course_name":  COURSE_NAMES.get(cid, cid),
            "base_course":  base_course(cid),
            "session_type": session_type(cid),
            "subgroup":     subgroup(cid),
            "session":      int(e["Session"]),
            "room":         room,
            "day":          day,
            "period":       period,
            "time":         PERIOD_TIMES.get(period, f"Period {period}"),
        }

        (mpi if track == "mpi" else cba).append(row)

    sort_key = lambda x: (DAY_ORDER.index(x["day"]), x["period"])
    mpi.sort(key=sort_key)
    cba.sort(key=sort_key)

    # Metrics
    metrics_raw = list(prolog.query("get_metrics(E, I, V, S)"))
    if metrics_raw:
        m = metrics_raw[0]
        metrics = {
            "energy":    int(m["E"]),
            "imbalance": int(m["I"]),
            "variance":  round(float(m["V"]), 4),
            "score":     round(float(m["S"]), 4),
        }
    else:
        metrics = {"energy": 0, "imbalance": 0, "variance": 0, "score": 0}

    return jsonify({
        "mpi":     mpi,
        "cba":     cba,
        "metrics": metrics,
        "elapsed": round(elapsed, 2),
    })


# ---------------------------------------------------------------------------
#  Routes
# ---------------------------------------------------------------------------

@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/schedule")
def api_schedule():
    try:
        t0 = time.perf_counter()
        list(prolog.query("generate_schedule"))
        elapsed = time.perf_counter() - t0
        return build_response(elapsed)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.route("/api/schedule/optimal")
def api_optimal():
    try:
        t0 = time.perf_counter()
        list(prolog.query("generate_optimal"))
        elapsed = time.perf_counter() - t0
        return build_response(elapsed)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# ---------------------------------------------------------------------------
#  Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("\n  INSAT Campus Scheduler UI")
    print("  http://localhost:5000\n")
    app.run(debug=True, port=5000)
