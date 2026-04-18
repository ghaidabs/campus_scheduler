%% ============================================================
%%  facts.pl  — Campus Knowledge Base
%%  All facts are ground (no variables). Think of this as your
%%  database. Every predicate has a clear, documented arity.
%% ============================================================

%% --- COURSES ---
%% course(Id, Group, Sessions, Duration, EquipNeeded)
%%   Id         : unique atom, e.g. c1
%%   Group      : student group atom, e.g. g1
%%   Sessions   : number of sessions per week (integer)
%%   Duration   : duration of one session in slots (integer)
%%   EquipNeeded: equipment type atom, e.g. projector, lab, standard

course(c1, g1, 2, 2, projector).   % Algorithms, group1, 2x per week, 2 slots each
course(c2, g1, 1, 3, lab).         % Database Lab, group1, 1x per week, 3 slots
course(c3, g2, 2, 2, standard).    % Math, group2, 2x per week, 2 slots each
course(c4, g2, 1, 2, projector).   % Networks, group2, 1x per week, 2 slots
course(c5, g3, 3, 1, standard).    % Physics, group3, 3x per week, 1 slot each

%% --- INSTRUCTOR AVAILABILITY ---
%% instructor_available(CourseId, TimeSlot)
%% A course can only be scheduled in slots where the instructor is free.
%% This is a SET of facts — one per (course, slot) pair.

instructor_available(c1, slot(monday,    1)).
instructor_available(c1, slot(monday,    2)).
instructor_available(c1, slot(wednesday, 1)).
instructor_available(c1, slot(wednesday, 2)).
instructor_available(c2, slot(tuesday,   1)).
instructor_available(c2, slot(tuesday,   2)).
instructor_available(c2, slot(tuesday,   3)).
instructor_available(c3, slot(monday,    3)).
instructor_available(c3, slot(thursday,  3)).
instructor_available(c4, slot(friday,    1)).
instructor_available(c4, slot(friday,    2)).
instructor_available(c5, slot(monday,    1)).
instructor_available(c5, slot(tuesday,   2)).
instructor_available(c5, slot(thursday,  1)).

%% --- ROOMS ---
%% room(Id, Capacity, Equipment, Building)
%%   Id       : unique atom, e.g. r1
%%   Capacity : integer (max students)
%%   Equipment: atom matching course requirements
%%   Building : atom matching a building Id

room(r1, 50, projector, b1).
room(r2, 30, standard,  b1).
room(r3, 20, lab,       b2).
room(r4, 40, projector, b2).
room(r5, 35, standard,  b3).

%% --- ENERGY COST ---
%% energy_cost(RoomId, CostPerSlot)
%% How many energy units does this room consume per slot?

energy_cost(r1, 5).   % Projector rooms cost more
energy_cost(r2, 2).
energy_cost(r3, 8).   % Labs cost the most
energy_cost(r4, 5).
energy_cost(r5, 2).

%% --- BUILDINGS ---
%% building(Id, DailyEnergyLimit)
%% Maximum total energy units per day per building.

building(b1, 40).
building(b2, 35).
building(b3, 25).

%% --- TIME SLOTS ---
%% time_slot(Id, Day, SlotNumber)
%% Slots are numbered 1..N per day. Slot 1 = first period, etc.

time_slot(slot(monday,    1), monday,    1).
time_slot(slot(monday,    2), monday,    2).
time_slot(slot(monday,    3), monday,    3).
time_slot(slot(tuesday,   1), tuesday,   1).
time_slot(slot(tuesday,   2), tuesday,   2).
time_slot(slot(tuesday,   3), tuesday,   3).
time_slot(slot(wednesday, 1), wednesday, 1).
time_slot(slot(wednesday, 2), wednesday, 2).
time_slot(slot(thursday,  1), thursday,  1).
time_slot(slot(thursday,  2), thursday,  2).
time_slot(slot(thursday,  3), thursday,  3).
time_slot(slot(friday,    1), friday,    1).
time_slot(slot(friday,    2), friday,    2).

%% --- STUDENT GROUP SIZES ---
%% group_size(GroupId, Size)
group_size(g1, 45).
group_size(g2, 28).
group_size(g3, 32).

%% --- ALL ROOMS (helper list, useful for iteration) ---
all_rooms([r1, r2, r3, r4, r5]).
all_buildings([b1, b2, b3]).
all_days([monday, tuesday, wednesday, thursday, friday]).