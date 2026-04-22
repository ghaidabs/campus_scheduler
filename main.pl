%% ============================================================
%%  main.pl -- INSAT Schedule Planner Entry Point
%%
%%  Quick start (SWI-Prolog REPL):
%%    ?- [main].           %% load all modules
%%    ?- run.              %% find ONE valid schedule (fast)
%%    ?- run_optimal.      %% find BEST schedule via best-of-200
%% ============================================================

:- [facts, constraints, scheduler, optimization].
:- use_module(library(json)).



%% ============================================================
%%  PRETTY PRINTING
%% ============================================================

period_label(1, '08h00-09h30').
period_label(2, '09h45-11h15').
period_label(3, '11h30-13h00').
period_label(5, '14h00-15h30').
period_label(6, '15h45-17h15').
period_label(7, '17h30-19h00').

day_name(monday,    'Monday   ').
day_name(tuesday,   'Tuesday  ').
day_name(wednesday, 'Wednesday').
day_name(thursday,  'Thursday ').
day_name(friday,    'Friday   ').

print_row(assign(Course, Session, Room, slot(Day, Period))) :-
    day_name(Day, D),
    period_label(Period, T),
    format("  | ~w s~w | ~w | ~w | ~w |~n",
           [Course, Session, D, T, Room]).

print_schedule([]).
print_schedule([A | Rest]) :-
    print_row(A),
    print_schedule(Rest).

div :-
    format("~`-t~70|~n").

header :-
    div,
    format("  | Course        | Day       | Time            | Room     |~n"),
    div.

print_metrics(Schedule) :-
    total_energy(Schedule, E),
    daily_imbalance(Schedule, I),
    room_usage_variance(Schedule, V),
    combined_score(Schedule, Score),
    format("~n  Energy total   : ~w units~n", [E]),
    format("  Daily imbalance: ~w units~n",   [I]),
    format("  Room variance  : ~4f~n",         [V]),
    format("  Combined score : ~4f~n",         [Score]).


%% ============================================================
%%  TRACK MEMBERSHIP  -- classify groups into MPI / CBA
%% ============================================================

mpi_group(g_mpi1_cm).
mpi_group(g_mpi1a).
mpi_group(g_mpi1b).

cba_group(g_cba1_cm).
cba_group(g_cba1a).
cba_group(g_cba1b).

%% True when Course belongs to the given Track (mpi / cba).
course_track(Course, mpi) :-
    course(Course, Group, _, _, _),
    mpi_group(Group), !.
course_track(Course, cba) :-
    course(Course, Group, _, _, _),
    cba_group(Group), !.

%% Filter a schedule to keep only assignments for a track.
filter_track([], _, []).
filter_track([assign(Course, S, R, Slot) | Rest], Track, [assign(Course, S, R, Slot) | Filtered]) :-
    course_track(Course, Track), !,
    filter_track(Rest, Track, Filtered).
filter_track([_ | Rest], Track, Filtered) :-
    filter_track(Rest, Track, Filtered).

%% Sort assignments by Day (Mon-Fri) then Period within each day.
assign_key(A, Key-A) :-
    A = assign(_, _, _, slot(Day, P)),
    day_order(Day, D),
    Key is D * 100 + P.

sort_schedule(Unsorted, Sorted) :-
    maplist(assign_key, Unsorted, Keyed),
    keysort(Keyed, SortedKeyed),
    pairs_values(SortedKeyed, Sorted).

%% Print a single track timetable with a banner.
print_track_schedule(Schedule, Track, Label) :-
    filter_track(Schedule, Track, Sub),
    sort_schedule(Sub, Sorted),
    nl, div,
    format("  ~w TIMETABLE~n", [Label]),
    header,
    print_schedule(Sorted),
    div.

%% Print both track timetables.
print_grouped_schedules(Schedule) :-
    print_track_schedule(Schedule, mpi, 'MPI (Maths-Physique-Informatique)'),
    print_track_schedule(Schedule, cba, 'CBA (Chimie-Biologie Appliquees)').


%% ============================================================
%%  run/0 -- First valid schedule (DFS, instant)
%% ============================================================

run :-
    div,
    write('  INSAT Timetable -- finding first valid schedule'), nl,
    div,
    (   schedule(Schedule)
    ->  print_grouped_schedules(Schedule),
        print_metrics(Schedule), nl
    ;   write('  No valid schedule found.'), nl
    ).


%% ============================================================
%%  run_optimal/0 -- Best of 200 schedules (practical optimum)
%%
%%  Samples the first 200 valid schedules from the DFS tree
%%  and returns the one with the lowest combined score.
%%  Balances solution quality against runtime.
%% ============================================================

run_optimal :-
    div,
    write('  INSAT Timetable -- optimising (best of 200 candidates)'), nl,
    div,
    N = 200,
    (   best_of_n(N, Best, Score)
    ->  format("~n  BEST SCHEDULE (score ~4f, sampled ~w candidates)~n", [Score, N]),
        print_grouped_schedules(Best),
        print_metrics(Best), nl
    ;   write('  No valid schedule found.'), nl
    ).