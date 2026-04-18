%% ============================================================
%%  scheduler.pl — Recursive Constraint Satisfaction Engine
%%
%%  The central predicate is:
%%    schedule_courses(+CourseSessions, +Partial, -Complete)
%%
%%  CourseSessions: list of (Course, SessionIndex) pairs to schedule
%%  Partial:        assignments built so far (the accumulator)
%%  Complete:       the final valid schedule
%% ============================================================

:- use_module(library(lists)).

%% ============================================================
%%  STEP 1: Build the work list
%%  Expand each course into N (course, session_index) pairs.
%%  e.g. course c1 with 2 sessions → [(c1,1),(c1,2)]
%% ============================================================

build_worklist([], []).
build_worklist([Course | Courses], WorkList) :-
    course(Course, _, Sessions, _, _),
    numlist(1, Sessions, Indices),
    maplist(pair(Course), Indices, Pairs),
    build_worklist(Courses, Rest),
    append(Pairs, Rest, WorkList).

pair(X, Y, X-Y).   % helper: pair(a, 1, a-1)

%% Convenience: collect all course IDs from facts
all_courses(Courses) :-
    findall(C, course(C, _, _, _, _), Courses).

%% ============================================================
%%  STEP 2: The recursive scheduler
%%
%%  Base case: no more sessions to schedule → done!
%%  Recursive case: pick the next session, find a valid
%%  (Room, Slot) assignment, add it to the partial schedule,
%%  and recurse on the remainder.
%%
%%  BACKTRACKING: If a later assignment fails, Prolog
%%  automatically backtracks to try a different (Room, Slot)
%%  for the current session, then tries a different session
%%  order if needed.
%% ============================================================

schedule_courses([], Schedule, Schedule).   % base case: all done

schedule_courses([Course-Session | Rest], Partial, FinalSchedule) :-
    %% Non-deterministically pick a room and slot:
    room(Room, _, _, _),            % try each room (via backtracking)
    time_slot(Slot, _, _),          % try each slot (via backtracking)
    
    %% Check ALL hard constraints before committing:
    all_hard_constraints(Course, Session, Room, Slot, Partial),
    
    %% If we reach here, this assignment is valid so far.
    %% Add it to the accumulator and continue:
    schedule_courses(
        Rest,
        [assign(Course, Session, Room, Slot) | Partial],
        FinalSchedule
    ).

%% ============================================================
%%  STEP 3: Top-level entry point
%%
%%  schedule(-Schedule) builds one complete valid schedule.
%%  To get ALL valid schedules, use findall/3.
%% ============================================================

schedule(Schedule) :-
    all_courses(Courses),
    build_worklist(Courses, WorkList),
    schedule_courses(WorkList, [], Schedule).

%% ============================================================
%%  STEP 4: Find the BEST schedule (for optimization)
%%
%%  This generates all valid schedules (expensive for large
%%  problems — use heuristics to prune first), scores each,
%%  and returns the one with the lowest total energy cost.
%% ============================================================

best_schedule(BestSchedule) :-
    findall(S, schedule(S), AllSchedules),   % find all valid schedules
    AllSchedules \= [],                      % fail if none exist
    score_and_pick_best(AllSchedules, BestSchedule).

score_and_pick_best([Only], Only) :- !.   % only one option
score_and_pick_best([S1 | Rest], Best) :-
    score_and_pick_best(Rest, BestOfRest),
    total_energy(S1, E1),
    total_energy(BestOfRest, E2),
    (E1 =< E2 -> Best = S1 ; Best = BestOfRest).