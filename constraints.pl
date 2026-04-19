%% ============================================================
%%  constraints.pl -- Hard Constraint Checker
%%
%%  BUGS FIXED vs original
%%  ----------------------
%%  1. energy_used/4: variable aliasing bug fixed.
%%     Original: Day in clause head == Day in slot(Day,_) pattern,
%%     so assignments from OTHER days crashed list traversal.
%%     Fix: renamed to AssignDay; if-then-else tests explicitly.
%%
%%  2. energy_budget_ok/3: Used =< Limit-Cost  =>  Used+Cost =< Limit.
%%
%%  3. no_room_conflict/3, no_group_conflict/3: rewritten with
%%     clean \+/member -- removed broken 4-argument versions.
%%
%%  4. equipment_compatible/2: extended for all INSAT equipment
%%     atoms: amphi_proj, it_lab, chem_lab, bio_lab.
%%
%%  NEW CONSTRAINT 7 -- No same-day repetition
%%  -------------------------------------------
%%  A course may not have two sessions on the same calendar day.
%%  This is a real-world pedagogical requirement (you don't teach
%%  the same course twice in one day) and is the primary fix for
%%  the Monday-clustering problem in the DFS output.
%% ============================================================

:- use_module(library(lists)).


%% ============================================================
%%  HARD CONSTRAINT 1 -- No room-time conflict
%% ============================================================

no_room_conflict(Room, Slot, Schedule) :-
    \+ member(assign(_, _, Room, Slot), Schedule).


%% ============================================================
%%  HARD CONSTRAINT 2 -- No group-time conflict
%% ============================================================

no_group_conflict(Group, Slot, Schedule) :-
    \+ (member(assign(OtherCourse, _, _, Slot), Schedule),
        course(OtherCourse, Group, _, _, _)).


%% ============================================================
%%  HARD CONSTRAINT 3 -- Room capacity
%% ============================================================

capacity_ok(Room, Group) :-
    group_size(Group, Size),
    room(Room, Capacity, _, _),
    Capacity >= Size.


%% ============================================================
%%  HARD CONSTRAINT 4 -- Equipment compatibility
%%
%%  Room hierarchy (RoomHas >= CourseNeeds):
%%    amphi_proj >= amphi_proj, projector, standard
%%    projector  >= projector, standard
%%    standard   >= standard  (only)
%%    it_lab, chem_lab, bio_lab: exact match only
%%
%%  equipment_compatible(CourseNeed, RoomHas)
%% ============================================================

equipment_compatible(standard,   standard).
equipment_compatible(standard,   projector).
equipment_compatible(standard,   amphi_proj).
equipment_compatible(projector,  projector).
equipment_compatible(projector,  amphi_proj).
equipment_compatible(amphi_proj, amphi_proj).
equipment_compatible(it_lab,     it_lab).
equipment_compatible(chem_lab,   chem_lab).
equipment_compatible(bio_lab,    bio_lab).

equipment_ok(Room, Course) :-
    course(Course, _, _, _, Required),
    room(Room, _, RoomEquip, _),
    equipment_compatible(Required, RoomEquip).


%% ============================================================
%%  HARD CONSTRAINT 5 -- Instructor availability
%% ============================================================

instructor_ok(Course, Slot) :-
    instructor_available(Course, Slot).


%% ============================================================
%%  HARD CONSTRAINT 6 -- Building energy budget
%%
%%  AssignDay (fresh variable) separates the slot's day from
%%  the query Day, fixing the original aliasing crash.
%% ============================================================

energy_used([], _, _, 0).
energy_used([assign(Course, _, Room, slot(AssignDay, _)) | Rest],
            Building, Day, Total) :-
    room(Room, _, _, RoomBuilding),
    (   RoomBuilding = Building, AssignDay = Day
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
    Used + Cost =< Limit.


%% ============================================================
%%  HARD CONSTRAINT 7 -- No same-day repetition (NEW)
%%
%%  A course cannot appear twice on the same calendar day.
%%  Prevents the DFS from booking both sessions of a course
%%  into adjacent slots on Monday, which produces a realistic
%%  but very imbalanced timetable.
%%
%%  "If the partial schedule already has a session of Course
%%   on Day, this new (Course, Day) pair is forbidden."
%% ============================================================

no_same_day_repeat(Course, Day, Schedule) :-
    \+ (member(assign(Course, _, _, slot(Day, _)), Schedule)).


%% ============================================================
%%  ALL HARD CONSTRAINTS COMBINED
%% ============================================================

all_hard_constraints(Course, _Session, Room, Slot, PartialSchedule) :-
    course(Course, Group, _, _, _),
    time_slot(Slot, Day, _),
    capacity_ok(Room, Group),
    equipment_ok(Room, Course),
    instructor_ok(Course, Slot),
    no_room_conflict(Room, Slot, PartialSchedule),
    no_group_conflict(Group, Slot, PartialSchedule),
    energy_budget_ok(Room, Day, PartialSchedule),
    no_same_day_repeat(Course, Day, PartialSchedule).   %% NEW