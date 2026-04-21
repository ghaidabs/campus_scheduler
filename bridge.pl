%% ============================================================
%%  bridge.pl -- Python-Prolog Bridge for the Web UI
%%
%%  Provides flat predicates that pyswip can query easily,
%%  avoiding the need to parse complex nested Prolog terms
%%  (like lists of assign/4 functors) on the Python side.
%%
%%  Usage via pyswip:
%%    prolog.query("generate_schedule")   → caches a schedule
%%    prolog.query("get_entry(C,S,R,D,P,T)") → iterate entries
%%    prolog.query("get_metrics(E,I,V,Sc)")  → get all metrics
%% ============================================================

:- [main].
:- dynamic cached_schedule/1.


%% --------------------------------------------------------------
%%  Schedule generation
%% --------------------------------------------------------------

%% Quick schedule: first valid DFS solution
generate_schedule :-
    retractall(cached_schedule(_)),
    schedule(S), !,
    assert(cached_schedule(S)).

%% Optimal schedule: best of 200 candidates
generate_optimal :-
    retractall(cached_schedule(_)),
    best_of_n(200, S, _), !,
    assert(cached_schedule(S)).


%% --------------------------------------------------------------
%%  Flat entry queries  (one row per backtrack)
%% --------------------------------------------------------------

get_entry(Course, Session, Room, Day, Period, Track) :-
    cached_schedule(S),
    member(assign(Course, Session, Room, slot(Day, Period)), S),
    (   course_track(Course, Track) -> true ; Track = unknown ).


%% --------------------------------------------------------------
%%  Metrics  (single solution)
%% --------------------------------------------------------------

get_metrics(Energy, Imbalance, Variance, Score) :-
    cached_schedule(S),
    total_energy(S, Energy),
    daily_imbalance(S, Imbalance),
    room_usage_variance(S, Variance),
    combined_score(S, Score).
