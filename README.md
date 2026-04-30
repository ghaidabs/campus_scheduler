# INSAT Campus Scheduler

INSAT Campus Scheduler is a Prolog-based course timetabling project for the Institut National des Sciences Appliquées et de Technologie (INSAT), Tunis. It builds weekly schedules for two first-year engineering tracks — MPI (Mathématiques, Physique, Informatique) and CBA (Chimie, Biologie Appliquées) — from a realistic campus knowledge base. The system enforces hard constraints such as room capacity, instructor availability, room conflicts, building energy limits, and no same-day course repetition, then scores valid schedules to find the best one. It can be used either from the SWI-Prolog command line or through a Flask web interface.

## Project Structure

- `facts.pl` — Knowledge base: 18 courses, 14 rooms across 3 building blocs, energy costs, instructor availability, time slots, and student group sizes for both MPI and CBA tracks.
- `constraints.pl` — Seven hard constraint checkers used during schedule construction (room conflict, group conflict, capacity, equipment, instructor availability, building energy budget, no same-day repetition).
- `scheduler.pl` — Expands courses into sessions and searches for valid schedules using backtracking with Most-Constrained-Variable ordering and sorted slot candidates.
- `optimization.pl` — Scores valid schedules with a weighted objective (energy, daily imbalance, room variance) and provides `best_of_n/3` for practical optimisation.
- `main.pl` — CLI entry point that loads all modules and prints timetables separated by track (MPI / CBA).
- `bridge.pl` — Python-Prolog bridge that exposes flat predicates (`generate_schedule`, `generate_optimal`, `get_entry/6`, `get_metrics/4`) for the Flask web server.
- `app.py` — Flask web server that serves the HTML frontend and two JSON API endpoints backed by the Prolog engine via pyswip.

## Requirements

**Command-line use (Prolog only)**
- SWI-Prolog 8.x or newer

**Web UI use (Flask + Prolog)**
- SWI-Prolog 8.x or newer
- Python 3.8 or newer
- Flask (`pip install flask`)
- pyswip (`pip install pyswip`)

## How To Run

### Command line (SWI-Prolog)

From the project directory, start SWI-Prolog and load the entry point:

```prolog
swipl
?- [main].
?- run.          % find the first valid schedule (fast, DFS)
?- run_optimal.  % find the best of 200 candidates (optimised)
```

You can also launch directly from a shell:

```bash
swipl -s main.pl -g run -t halt
swipl -s main.pl -g run_optimal -t halt
```

### Web UI (Flask)

```bash
python app.py
```

Then open `http://localhost:5000` in your browser.

The server exposes two JSON endpoints:

- `GET /api/schedule` — returns the first valid DFS schedule.
- `GET /api/schedule/optimal` — returns the best of 200 schedules.

## What The Program Does

When you call `run`, the system:

1. Loads the course and resource facts.
2. Builds a work list ordered by Most Constrained Variable (fewest instructor-available slots first).
3. For each session, enumerates instructor-available time slots (sorted Monday→Friday) and viable rooms (pre-filtered by capacity and equipment).
4. Rejects invalid assignments immediately when a hard constraint is violated.
5. Prints the first valid schedule it finds, separated into MPI and CBA track timetables.

When you call `run_optimal`, the system samples the first 200 valid schedules produced by the DFS engine and prints the one with the lowest combined score.

## Time Slots

INSAT uses a 5-day week (Monday–Friday) with 6 usable 90-minute periods per day. Period 4 (12:30–14:00, lunch break) is excluded from scheduling.

| Period | Time            |
|--------|-----------------|
| 1      | 08:00 – 09:30   |
| 2      | 09:45 – 11:15   |
| 3      | 11:30 – 13:00   |
| 5      | 14:00 – 15:30   |
| 6      | 15:45 – 17:15   |
| 7      | 17:30 – 19:00   |

## Constraints And Scoring

The scheduler enforces these hard constraints:

1. No room can host two sessions at the same time.
2. A student group cannot attend two sessions at once (full cohort and its subgroups are treated as conflicting).
3. Room capacity must be large enough for the group.
4. Room equipment must satisfy the course requirement.
5. A course can only use instructor-available time slots.
6. The building energy budget must not be exceeded for a given day.
7. A course cannot have two sessions on the same calendar day.

Valid schedules are ranked using a weighted score:

```
Score = 1.0 × total_energy + 0.5 × daily_imbalance + 0.3 × room_variance
```

Lower scores are better.

## Customizing The Model

You can adapt the schedule by editing the facts in `facts.pl`:

- Add or remove courses.
- Change the number of sessions or their duration.
- Adjust room capacities and equipment types.
- Update instructor availability.
- Tune building energy limits or room energy costs.

If you change the objective weights, update them in `optimization.pl`.

## Example Output

Running `run` prints two track timetables in this format:

```text
----------------------------------------------------------------------
  MPI (Maths-Physique-Informatique) TIMETABLE
----------------------------------------------------------------------
  | Course        | Day       | Time            | Room     |
----------------------------------------------------------------------
  | c_algo_cm s1  | Monday    | 08:00 – 09:30   | amphi_a1 |
  | c_analyse_cm s1 | Tuesday | 09:45 – 11:15   | amphi_a1 |
  ...
----------------------------------------------------------------------
  CBA (Chimie-Biologie Appliquees) TIMETABLE
----------------------------------------------------------------------
  | c_chimie_cm s1 | Monday   | 09:45 – 11:15   | amphi_a2 |
  ...

  Energy total   : 312 units
  Daily imbalance: 48 units
  Room variance  : 1.2400
  Combined score : 360.3720
```

The exact result depends on the current facts and the search order.

## Notes

- The project is self-contained and models a realistic INSAT Year-1 timetabling problem (18 courses, 34 weekly sessions, 14 rooms, two tracks).
- The search space grows quickly as you add more courses, rooms, and time slots, so larger instances may need extra heuristics or pruning.
- For the web UI, pyswip must be able to find the SWI-Prolog shared library. Set `SWI_HOME_DIR` or `LD_LIBRARY_PATH` if pyswip cannot locate it automatically.
