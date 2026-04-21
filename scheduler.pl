%% ============================================================
%%  scheduler.pl -- Recursive Constraint Satisfaction Engine
%%
%%  IMPROVEMENTS vs original
%%  ------------------------
%%  1. PERFORMANCE: Enumerate instructor_available(Course,Slot)
%%     first (~5 slots) instead of all time_slots (~30). This
%%     gives a ~6x reduction in branching factor per level.
%%
%%  2. PERFORMANCE: room_for_course/2 pre-filters rooms by
%%     capacity + equipment before conflict checks run.
%%
%%  3. QUALITY: Most-Constrained-Variable (MCV) ordering.
%%     The worklist is sorted so that courses with the fewest
%%     available instructor slots are scheduled FIRST. This
%%     dramatically reduces backtracking by catching dead-ends
%%     early (fail-first heuristic).
%%
%%  4. QUALITY: Slot candidates are sorted by (Day, Period)
%%     so that DFS distributes sessions across the week
%%     naturally, rather than piling everything on Monday.
%%     Combined with Constraint 7 (no same-day repeat), the
%%     resulting timetable is well-spread by construction.
%% ============================================================

:- use_module(library(lists)).


%% ============================================================
%%  Day ordering for slot sorting
%%  Maps day atoms to integers so we can sort slots by day.
%% ============================================================

day_order(monday,    1).
day_order(tuesday,   2).
day_order(wednesday, 3).
day_order(thursday,  4).
day_order(friday,    5).


%% ============================================================
%%  STEP 1 -- Build the work list  (MCV ordered)
%%
%%  Each course expands into N (Course-SessionIndex) pairs.
%%  The list is then sorted: courses with FEWER available
%%  instructor slots come first (Most Constrained Variable).
%%  Within a course, sessions are ordered 1..N.
%% ============================================================

generate_indices(N, N, [N]) :- !.
generate_indices(I, N, [I | Rest]) :-
    I < N,
    I1 is I + 1,
    generate_indices(I1, N, Rest).

make_pair(Course, Index, Course-Index).

%% Count how many distinct instructor-available slots a course has.
slot_count(Course, Count) :-
    findall(S, instructor_available(Course, S), Slots),
    length(Slots, Count).

%% Build pairs sorted by slot count (MCV first).
build_worklist(Courses, WorkList) :-
    maplist(course_with_count, Courses, Counted),
    keysort(Counted, Sorted),
    pairs_values(Sorted, SortedCourses),
    maplist(expand_course, SortedCourses, NestedPairs),
    flatten(NestedPairs, WorkList).

course_with_count(Course, Count-Course) :-
    slot_count(Course, Count).

expand_course(Course, Pairs) :-
    course(Course, _, Sessions, _, _),
    generate_indices(1, Sessions, Indices),
    maplist(make_pair(Course), Indices, Pairs).


%% ============================================================
%%  STEP 2 -- Viable room predicate
%%
%%  Pre-filters rooms to those satisfying capacity + equipment.
%% ============================================================

room_for_course(Course, Room) :-
    course(Course, Group, _, _, _),
    room(Room, _, _, _),
    capacity_ok(Room, Group),
    equipment_ok(Room, Course).


%% ============================================================
%%  STEP 3 -- Sorted slot candidates
%%
%%  Returns the instructor-available slots for a course,
%%  sorted by (Day, Period) so that DFS explores Monday
%%  slots before Tuesday, etc.  This, combined with Constraint
%%  7 (no same-day repeat), naturally spreads the timetable.
%% ============================================================

sorted_slots(Course, SortedSlots) :-
    findall(slot(Day, P), instructor_available(Course, slot(Day, P)), Slots),
    maplist(slot_key, Slots, KeyedSlots),
    keysort(KeyedSlots, SortedKeyed),
    pairs_values(SortedKeyed, SortedSlots).

slot_key(slot(Day, P), Key-slot(Day, P)) :-
    day_order(Day, D),
    Key is D * 100 + P.

%% member/2 over a list for backtracking through sorted slots
member_slot(Slot, [Slot | _]).
member_slot(Slot, [_ | Rest]) :- member_slot(Slot, Rest).


%% ============================================================
%%  STEP 4 -- Recursive scheduler
%% ============================================================

schedule_courses([], Schedule, Schedule).

schedule_courses([Course-Session | Rest], Partial, FinalSchedule) :-
    sorted_slots(Course, Slots),          %% (A) sorted available slots
    member_slot(Slot, Slots),             %% (B) enumerate in day order
    room_for_course(Course, Room),        %% (C) viable rooms only
    all_hard_constraints(Course, Session, Room, Slot, Partial),
    schedule_courses(
        Rest,
        [assign(Course, Session, Room, Slot) | Partial],
        FinalSchedule
    ).


%% ============================================================
%%  STEP 5 -- Top-level entry point
%% ============================================================

schedule(Schedule) :-
    all_courses(Courses),
    build_worklist(Courses, WorkList),
    schedule_courses(WorkList, [], Schedule).


%% ============================================================
%%  STEP 6 -- Best schedule helpers
%% ============================================================

best_schedule(BestSchedule) :-
    findall(S, schedule(S), AllSchedules),
    AllSchedules \= [],
    pick_best(AllSchedules, BestSchedule).

pick_best([Only], Only) :- !.
pick_best([S1 | Rest], Best) :-
    pick_best(Rest, BestOfRest),
    combined_score(S1, E1),
    combined_score(BestOfRest, E2),
    ( E1 =< E2 -> Best = S1 ; Best = BestOfRest ).