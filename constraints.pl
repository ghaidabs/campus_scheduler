%% ============================================================
%%  constraints.pl — Feasibility Checker
%%
%%  Design principle: CHECK EARLY, FAIL FAST.
%%  Every constraint is checked as soon as the information
%%  needed for it is available — not after a full schedule
%%  is built. This is what prevents combinatorial explosion.
%% ============================================================

:- use_module(library(lists)).

%% ============================================================
%%  HARD CONSTRAINT 1: No room-time conflict
%%  A room can host at most one session at a time.
%%
%%  We check this against the PARTIAL schedule built so far
%%  (the accumulator). If the new assignment conflicts with
%%  any existing one, fail immediately and backtrack.
%% ============================================================
%% Condition -> Then ; Else

no_room_conflict(_, _, [], _).
no_room_conflict(Room, Slot, [assign(_, _, OtherRoom, OtherSlot) | Rest], Duration) :-
    (   Room = OtherRoom, Slot = OtherSlot
    ->  fail   % Same room, same slot: hard conflict
    ;   no_room_conflict(Room, Slot, Rest, Duration)
    ).

%% ============================================================
%%  HARD CONSTRAINT 2: No group-time conflict
%%  A student group cannot attend two sessions simultaneously.
%% ============================================================

no_group_conflict(_, _, [], _).
no_group_conflict(Group, Slot, [assign(OtherCourse, _, _, OtherSlot) | Rest], Group) :-
    (   Slot = OtherSlot,
        course(OtherCourse, Group, _, _, _)
    ->  fail
    ;   no_group_conflict(Group, Slot, Rest, Group)
    ).

%% ============================================================
%%  HARD CONSTRAINT 3: Room capacity
%%  Room must hold all students in the group.
%% ============================================================

capacity_ok(Room, Group) :-
    group_size(Group, Size),
    room(Room, Capacity, _, _),
    Capacity >= Size.

%% ============================================================
%%  HARD CONSTRAINT 4: Equipment compatibility
%%  Room equipment must match what the course requires.
%% ============================================================

equipment_ok(Room, Course) :-
    course(Course, _, _, _, Required),
    room(Room, _, RoomEquip, _),
    equipment_compatible(Required, RoomEquip).

%% Equipment compatibility rules:
%% A room with "projector" can host courses needing "standard" too
%% (it has everything standard rooms have, plus more).
equipment_compatible(standard,  standard).
equipment_compatible(standard,  projector).  % projector rooms work for standard too
equipment_compatible(projector, projector).
equipment_compatible(lab,       lab).

%% ============================================================
%%  HARD CONSTRAINT 5: Instructor availability
%%  The time slot must be in the instructor's available set.
%% ============================================================

instructor_ok(Course, Slot) :-
    instructor_available(Course, Slot).

%% ============================================================
%%  HARD CONSTRAINT 6: Building energy budget
%%  Accumulated energy in a building on a given day must not
%%  exceed the building's daily threshold.
%%
%%  This is the trickiest constraint because it requires
%%  summing over the partial schedule. We pass the current
%%  energy state as an ACCUMULATOR into the scheduler.
%% ============================================================

%% Compute current energy used in building B on Day from partial schedule
energy_used([], _, _, 0).
energy_used([assign(Course, _, Room, slot(Day, _)) | Rest], Building, Day, Total) :-
    room(Room, _, _, RoomBuilding),
    (   RoomBuilding = Building
    ->  energy_cost(Room, Cost),
        course(Course, _, _, Duration, _),
        energy_used(Rest, Building, Day, RestTotal),
        Total is RestTotal + Cost * Duration
    ;   energy_used(Rest, Building, Day, Total)
    ).

energy_budget_ok(Room, Day, PartialSchedule) :-
    room(Room, _, _, Building),
    building(Building, Limit),
    energy_used(PartialSchedule, Building, Day, Used),
    energy_cost(Room, Cost),
    Used =< Limit - Cost.   % Check BEFORE adding; leave room for this session

%% ============================================================
%%  ALL HARD CONSTRAINTS combined
%%  This is called once per candidate assignment.
%%  If any sub-check fails, Prolog backtracks immediately.
%% ============================================================

all_hard_constraints(Course, Session, Room, Slot, PartialSchedule) :-
    course(Course, Group, _, _, _),          % extract group
    time_slot(Slot, Day, _),                 % extract day
    capacity_ok(Room, Group),                % constraint 3
    equipment_ok(Room, Course),              % constraint 4
    instructor_ok(Course, Slot),             % constraint 5
    no_room_conflict(Room, Slot, PartialSchedule, _),   % constraint 1
    no_group_conflict(Group, Slot, PartialSchedule, _), % constraint 2
    energy_budget_ok(Room, Day, PartialSchedule).        % constraint 6