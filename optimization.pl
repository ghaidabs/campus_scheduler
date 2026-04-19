%% ============================================================
%%  optimization.pl -- Multi-Criteria Schedule Evaluation
%%
%%  Three optimisation axes:
%%    1. Total energy consumption  (minimise)
%%    2. Daily energy imbalance    (minimise spread across week)
%%    3. Room usage variance       (minimise unfairness)
%%
%%  Score = W1 * energy + W2 * imbalance + W3 * variance
%%
%%  Entry points:
%%    greedy_schedule(S, Score)   -- first DFS solution (fast)
%%    best_of_n(N, S, Score)      -- best of first N solutions
%%    optimal_schedule(S)         -- branch-and-bound (exhaustive)
%% ============================================================


%% ============================================================
%%  UTILITY
%% ============================================================

sumlist_([], 0).
sumlist_([H | T], Sum) :-
    sumlist_(T, Rest),
    Sum is Rest + H.


%% ============================================================
%%  METRIC 1 -- Total energy consumption
%% ============================================================

total_energy([], 0).
total_energy([assign(Course, _, Room, _) | Rest], Total) :-
    energy_cost(Room, Cost),
    course(Course, _, _, Duration, _),
    total_energy(Rest, RestTotal),
    Total is RestTotal + Cost * Duration.


%% ============================================================
%%  METRIC 2 -- Daily energy imbalance
%% ============================================================

on_day(Day, assign(_, _, _, slot(Day, _))).

daily_energy(Schedule, Day, DayTotal) :-
    include(on_day(Day), Schedule, DayAssigns),
    total_energy(DayAssigns, DayTotal).

daily_imbalance(Schedule, Imbalance) :-
    all_days(Days),
    maplist(daily_energy(Schedule), Days, Energies),
    max_list(Energies, MaxE),
    min_list(Energies, MinE),
    Imbalance is MaxE - MinE.


%% ============================================================
%%  METRIC 3 -- Room usage variance
%% ============================================================

sq_diff(Mean, X, D) :- D is (X - Mean) * (X - Mean).

uses_room(Room, assign(_, _, Room, _)).

room_usage(Schedule, Room, Usage) :-
    include(uses_room(Room), Schedule, Used),
    length(Used, Usage).

room_usage_variance(Schedule, Variance) :-
    all_rooms(Rooms),
    maplist(room_usage(Schedule), Rooms, Usages),
    length(Usages, N),
    sumlist_(Usages, Total),
    Mean is Total / N,
    maplist(sq_diff(Mean), Usages, SqDiffs),
    sumlist_(SqDiffs, SqDiffTotal),
    Variance is SqDiffTotal / N.


%% ============================================================
%%  COMBINED SCORE
%% ============================================================

combined_score(Schedule, Score) :-
    W1 = 1.0,   %% energy total
    W2 = 0.5,   %% daily imbalance
    W3 = 0.3,   %% room variance
    total_energy(Schedule, E),
    daily_imbalance(Schedule, I),
    room_usage_variance(Schedule, V),
    Score is W1 * float(E) + W2 * float(I) + W3 * V.


%% ============================================================
%%  GREEDY SCHEDULE  (fast: first DFS solution)
%% ============================================================

greedy_schedule(Schedule, Score) :-
    schedule(Schedule),
    combined_score(Schedule, Score).


%% ============================================================
%%  BEST-OF-N  (practical optimisation)
%%
%%  Samples the first N valid schedules produced by the DFS
%%  engine and returns the one with the lowest combined score.
%%  Much faster than full exhaustive search when there are
%%  thousands of valid schedules (as in the INSAT problem).
%%
%%  N = 200 gives a good quality/speed balance for this
%%  instance. Increase for better quality; decrease for speed.
%% ============================================================

best_of_n(N, BestSchedule, BestScore) :-
    collect_n(N, Pairs),
    Pairs \= [],
    keysort(Pairs, [BestScore-BestSchedule | _]).

collect_n(N, Pairs) :-
    nb_setval(bon_count, 0),
    nb_setval(bon_pairs, []),
    forall(
        (   schedule(S),
            nb_getval(bon_count, C), C1 is C + 1,
            nb_setval(bon_count, C1),
            combined_score(S, Score),
            nb_getval(bon_pairs, Acc),
            nb_setval(bon_pairs, [Score-S | Acc]),
            C1 >= N, !
        ),
        true
    ),
    nb_getval(bon_pairs, Pairs).


%% ============================================================
%%  BRANCH-AND-BOUND OPTIMAL  (exhaustive; slow if many solutions)
%%
%%  Iteratively improves: finds first solution, then repeatedly
%%  searches for a strictly better one until none exists.
%%
%%  Use this only for small, well-constrained instances.
%%  For the full INSAT problem, use best_of_n/3 instead.
%% ============================================================

optimal_schedule(BestSchedule) :-
    schedule(FirstSolution),
    combined_score(FirstSolution, FirstScore),
    bnb(FirstSolution, FirstScore, BestSchedule).

bnb(CurrentBest, CurrentScore, FinalBest) :-
    (   schedule(Candidate),
        combined_score(Candidate, CandScore),
        CandScore < CurrentScore
    ->  bnb(Candidate, CandScore, FinalBest)
    ;   FinalBest = CurrentBest
    ).