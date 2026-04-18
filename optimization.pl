%% ============================================================
%%  optimization.pl — Multi-Criteria Schedule Evaluation
%%
%%  We score a schedule on THREE axes:
%%    1. Total energy consumption (minimize)
%%    2. Daily load imbalance (minimize)
%%    3. Room usage fairness / variance (minimize)
%%
%%  A combined score lets us compare two schedules as a
%%  single number.
%% ============================================================

%% ============================================================
%%  METRIC 1: Total energy consumption
%%  E_total = sum over all assignments of (energy_cost * duration)
%% ============================================================

total_energy([], 0).
total_energy([assign(Course, _, Room, _) | Rest], Total) :-
    energy_cost(Room, Cost),
    course(Course, _, _, Duration, _),
    total_energy(Rest, RestTotal),
    Total is RestTotal + Cost * Duration.

%% ============================================================
%%  METRIC 2: Daily energy imbalance
%%  Imbalance = sum over days of (max_daily - min_daily)
%%  Lower = more balanced energy spread across the week.
%% ============================================================

daily_energy(Schedule, Day, DayTotal) :-
    include(on_day(Day), Schedule, DayAssignments),
    total_energy(DayAssignments, DayTotal).

on_day(Day, assign(_, _, _, slot(Day, _))).

%% Filter assignments belonging to a given day:
on_day_filter(Day, assign(_, _, _, slot(Day, _))).   % for include/3

daily_imbalance(Schedule, Imbalance) :-
    all_days(Days),
    maplist(daily_energy(Schedule), Days, Energies),
    max_list(Energies, MaxE),
    min_list(Energies, MinE),
    Imbalance is MaxE - MinE.

%% ============================================================
%%  METRIC 3: Room usage fairness (variance)
%%  Var(R) = (1/m) * sum_j (usage(rj) - mean_usage)^2
%%  Lower variance = more balanced room use.
%% ============================================================

room_usage(Schedule, Room, Usage) :-
    include(uses_room(Room), Schedule, RoomAssignments),
    length(RoomAssignments, Usage).

uses_room(Room, assign(_, _, Room, _)).

room_usage_variance(Schedule, Variance) :-
    all_rooms(Rooms),
    maplist(room_usage(Schedule), Rooms, Usages),
    length(Usages, N),
    sumlist(Usages, Total),
    Mean is Total / N,
    maplist(sq_diff(Mean), Usages, SqDiffs),
    sumlist(SqDiffs, SqDiffTotal),
    Variance is SqDiffTotal / N.

sq_diff(Mean, X, D) :- D is (X - Mean) * (X - Mean).

%% ============================================================
%%  COMBINED SCORE
%%  We use a weighted sum of the three metrics.
%%  Weights are tunable — document your choice in the report!
%%
%%  score = W1 * energy + W2 * imbalance + W3 * variance
%% ============================================================

combined_score(Schedule, Score) :-
    W1 = 1.0,   % weight for total energy
    W2 = 0.5,   % weight for daily imbalance
    W3 = 0.3,   % weight for room variance
    total_energy(Schedule, E),
    daily_imbalance(Schedule, I),
    room_usage_variance(Schedule, V),
    Score is W1 * E + W2 * I + W3 * V.

%% ============================================================
%%  SELECT OPTIMAL SCHEDULE
%% ============================================================

optimal_schedule(Best) :-
    findall(Schedule, schedule(Schedule), All),
    All \= [],
    maplist(score_schedule, All, Scored),
    keysort(Scored, [_-Best | _]).   % lowest score first

score_schedule(S, Score-S) :-
    combined_score(S, Score).