# Campus Scheduler

Campus Scheduler is a Prolog-based course timetabling project. It builds weekly schedules from a small campus knowledge base, checks hard constraints such as room capacity, instructor availability, room conflicts, and building energy limits, then scores valid schedules to pick the best one.

## Project Structure

- `facts.pl` contains the knowledge base: courses, rooms, buildings, energy costs, instructor availability, time slots, and group sizes.
- `constraints.pl` implements the feasibility checks used while constructing schedules.
- `scheduler.pl` expands courses into sessions and searches for valid schedules using backtracking.
- `optimization.pl` scores valid schedules and selects the best one with a weighted objective.
- `main.pl` is the entry point that loads the modules and prints the optimal schedule.

## Requirements

- SWI-Prolog 8.x or newer

## How To Run

From the project directory, start SWI-Prolog and load the entry point:

```prolog
swipl
?- [main].
?- run.
```

If your Prolog installation already starts in the project directory, you can also launch it in one step:

```bash
swipl -s main.pl -g run -t halt
```

## What The Program Does

When you call `run`, the system:

1. Loads the course and resource facts.
2. Generates candidate room and time-slot assignments for every course session.
3. Rejects invalid assignments immediately when a hard constraint is violated.
4. Evaluates each valid schedule with a combined score.
5. Prints the lowest-scoring schedule it can find.

## Constraints And Scoring

The scheduler enforces these hard constraints:

- No room can host two sessions at the same time.
- A student group cannot attend two sessions at once.
- Room capacity must be large enough for the group.
- Room equipment must satisfy the course requirement.
- A course can only use instructor-available time slots.
- The building energy budget must not be exceeded for a given day.

Valid schedules are ranked using a weighted score based on:

- Total energy consumption
- Daily energy imbalance
- Room usage fairness

Lower scores are better.

## Customizing The Model

You can adapt the schedule by editing the facts in `facts.pl`:

- Add or remove courses.
- Change the number of sessions or their duration.
- Adjust room capacities and equipment types.
- Update instructor availability.
- Tune building energy limits or room energy costs.

If you change the objective, update the weights in `optimization.pl`.

## Example Output

Running `run` prints assignments in this format:

```text
Searching for optimal schedule...
=== OPTIMAL SCHEDULE ===
	c1 session 1 -> room r4 at slot(monday,1)
	c1 session 2 -> room r1 at slot(wednesday,2)
	...
Combined score: 42.50
```

The exact result depends on the current facts and the search order.

## Notes

- The project is intentionally small and self-contained, so it can be used for coursework, experimentation, or as a starting point for more advanced timetabling rules.
- The search space grows quickly as you add more courses, rooms, and time slots, so larger instances may need extra heuristics or pruning.
