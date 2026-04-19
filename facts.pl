%% ============================================================
%%  facts.pl  -- INSAT Campus Knowledge Base
%%  Institut National des Sciences Appliquees et de Technologie
%%  Centre Urbain Nord, BP 676 -- 1080 Tunis Cedex
%%
%%  Models a realistic weekly schedule for two departments:
%%    * DGIM  -- Genie Informatique et Mathematiques
%%    * GBC   -- Genie Biologique et Chimique
%%
%%  Structure:
%%    - 8 courses, 15 weekly sessions total
%%    - 14 rooms across 3 building blocs
%%    - 5-day week, 6 usable time slots per day (lunch excluded)
%%
%%  REAL-WORLD CONTEXT
%%  ------------------
%%  INSAT (founded 1992, affiliated with Universite de Carthage)
%%  has ~2260 students, 166 instructors, and offers 5-year
%%  engineering programmes in two main tracks:
%%    MPI  -- Mathematiques, Physique, Informatique
%%    CBA  -- Chimie, Biologie Appliquees
%%  Specialisations (years 3-5): GL, RT, IIA, CI, BI, IMI.
%%
%%  DESIGN GUARANTEE
%%  ----------------
%%  Every course has:
%%    (a) >= (sessions + 2) instructor-available slots,
%%    (b) at least one room satisfying capacity AND equipment,
%%    (c) energy costs well under building daily limits.
%% ============================================================


%% ============================================================
%%  STUDENT GROUPS
%%  group_size(GroupId, NbStudents)
%%
%%  Year-1 MPI: full cohort in amphitheatre (CM), then split
%%  into subgroups A/B for TD/TP sessions.
%%  Years 3-4: smaller specialisation groups.
%% ============================================================

group_size(g_mpi1_cm,  80).   %% MPI Year-1 combined  (amphitheatre CM)
group_size(g_mpi1a,    35).   %% MPI Year-1 subgroup A  (TD / TP)
group_size(g_mpi1b,    35).   %% MPI Year-1 subgroup B  (TD / TP)
group_size(g_gl3,      25).   %% Genie Logiciel Year-3
group_size(g_rt3,      25).   %% Reseaux & Telecommunications Year-3
group_size(g_iia4,     20).   %% Informatique Industrielle & Automatique Year-4
group_size(g_cba2,     28).   %% Chimie-Biologie Appliquees Year-2


%% ============================================================
%%  COURSES
%%  course(Id, Group, SessionsPerWeek, Duration, EquipNeeded)
%%
%%  Duration = 1 for all courses (one 90-min slot per session).
%%  This matches the standard INSAT slot grid.
%%
%%  Equipment atoms: amphi_proj | projector | standard |
%%                   it_lab     | chem_lab  | bio_lab
%%
%%  DGIM department ------------------------------------------
%%    c_algo_cm    Algorithmique -- cours magistral (lecture)
%%    c_algo_tp_a  Algorithmique -- TP subgroup A
%%    c_algo_tp_b  Algorithmique -- TP subgroup B
%%    c_gl_arch    Architecture Logicielle (GL year 3)
%%    c_reseaux    Reseaux Informatiques  (RT year 3)
%%    c_auto       Automatique & Controle (IIA year 4)
%%
%%  GBC department -------------------------------------------
%%    c_chimie     Chimie Organique -- TP
%%    c_bio_tp     Biologie Moleculaire -- TP
%% ============================================================

course(c_algo_cm,   g_mpi1_cm, 2, 1, amphi_proj).
course(c_algo_tp_a, g_mpi1a,   2, 1, it_lab).
course(c_algo_tp_b, g_mpi1b,   2, 1, it_lab).
course(c_gl_arch,   g_gl3,     2, 1, it_lab).
course(c_reseaux,   g_rt3,     2, 1, it_lab).
course(c_auto,      g_iia4,    2, 1, projector).
course(c_chimie,    g_cba2,    2, 1, chem_lab).
course(c_bio_tp,    g_cba2,    1, 1, bio_lab).


%% ============================================================
%%  ROOMS
%%  room(Id, Capacity, Equipment, Building)
%%
%%  Bloc A -- Main academic building (amphitheatres + TD rooms)
%%  Bloc B -- Informatique building  (IT labs + TD room)
%%            INSAT has ~50 IT labs on campus; we model 4.
%%  Bloc C -- Sciences building      (chem labs + bio lab + TD)
%% ============================================================

%% Bloc A
room(amphi_a1, 200, amphi_proj, bloc_a).   %% Grand amphitheatre
room(amphi_a2, 150, amphi_proj, bloc_a).   %% Amphitheatre B
room(td_a1,     40, projector,  bloc_a).   %% Salle TD -- videoprojecteur
room(td_a2,     40, standard,   bloc_a).   %% Salle TD -- standard
room(td_a3,     40, standard,   bloc_a).   %% Salle TD -- standard

%% Bloc B
room(it_b1, 40, it_lab,   bloc_b).   %% Labo Informatique 1
room(it_b2, 40, it_lab,   bloc_b).   %% Labo Informatique 2
room(it_b3, 40, it_lab,   bloc_b).   %% Labo Informatique 3
room(it_b4, 40, it_lab,   bloc_b).   %% Labo Informatique 4
room(td_b1, 35, standard, bloc_b).   %% Salle TD

%% Bloc C
room(chem_c1, 30, chem_lab, bloc_c).   %% Labo Chimie 1
room(chem_c2, 30, chem_lab, bloc_c).   %% Labo Chimie 2
room(bio_c1,  30, bio_lab,  bloc_c).   %% Labo Biologie Moleculaire
room(td_c1,   35, standard, bloc_c).   %% Salle TD -- Sciences


%% ============================================================
%%  ENERGY COST
%%  energy_cost(RoomId, UnitsPerSlot)
%%
%%  Amphitheatres and specialist labs consume more energy.
%%  Standard TD rooms are cheap; IT labs moderate.
%% ============================================================

energy_cost(amphi_a1, 15).
energy_cost(amphi_a2, 12).
energy_cost(td_a1,     4).
energy_cost(td_a2,     3).
energy_cost(td_a3,     3).
energy_cost(it_b1,     8).
energy_cost(it_b2,     8).
energy_cost(it_b3,     8).
energy_cost(it_b4,     8).
energy_cost(td_b1,     3).
energy_cost(chem_c1,  10).
energy_cost(chem_c2,  10).
energy_cost(bio_c1,    8).
energy_cost(td_c1,     3).


%% ============================================================
%%  BUILDINGS
%%  building(Id, DailyEnergyLimit)
%%
%%  Limits are generous enough to avoid artificial dead ends
%%  while still exercising the energy constraint logic.
%% ============================================================

building(bloc_a, 200).
building(bloc_b, 200).
building(bloc_c, 150).


%% ============================================================
%%  TIME SLOTS
%%  time_slot(SlotId, Day, PeriodNumber)
%%
%%  INSAT timetable: Monday-Friday, 8 periods per day.
%%  Periods: 1=08h00  2=09h30  3=11h00  [4=lunch break]
%%           5=14h00  6=15h30  7=17h00
%%  Period 4 (lunch, 12h30-14h00) is excluded from scheduling.
%%  Usable: 6 periods/day x 5 days = 30 slots total.
%% ============================================================

time_slot(slot(monday,    1), monday,    1).
time_slot(slot(monday,    2), monday,    2).
time_slot(slot(monday,    3), monday,    3).
time_slot(slot(monday,    5), monday,    5).
time_slot(slot(monday,    6), monday,    6).
time_slot(slot(monday,    7), monday,    7).

time_slot(slot(tuesday,   1), tuesday,   1).
time_slot(slot(tuesday,   2), tuesday,   2).
time_slot(slot(tuesday,   3), tuesday,   3).
time_slot(slot(tuesday,   5), tuesday,   5).
time_slot(slot(tuesday,   6), tuesday,   6).
time_slot(slot(tuesday,   7), tuesday,   7).

time_slot(slot(wednesday, 1), wednesday, 1).
time_slot(slot(wednesday, 2), wednesday, 2).
time_slot(slot(wednesday, 3), wednesday, 3).
time_slot(slot(wednesday, 5), wednesday, 5).
time_slot(slot(wednesday, 6), wednesday, 6).
time_slot(slot(wednesday, 7), wednesday, 7).

time_slot(slot(thursday,  1), thursday,  1).
time_slot(slot(thursday,  2), thursday,  2).
time_slot(slot(thursday,  3), thursday,  3).
time_slot(slot(thursday,  5), thursday,  5).
time_slot(slot(thursday,  6), thursday,  6).
time_slot(slot(thursday,  7), thursday,  7).

time_slot(slot(friday,    1), friday,    1).
time_slot(slot(friday,    2), friday,    2).
time_slot(slot(friday,    3), friday,    3).
time_slot(slot(friday,    5), friday,    5).
time_slot(slot(friday,    6), friday,    6).
time_slot(slot(friday,    7), friday,    7).


%% ============================================================
%%  INSTRUCTOR AVAILABILITY
%%  instructor_available(CourseId, SlotId)
%%
%%  Each course has >= (sessions + 2) available slots so the
%%  scheduler always has room to manoeuvre and sessions are
%%  naturally distributed across the week.
%% ============================================================

%% c_algo_cm -- Algorithmique CM  (2 sessions needed, 6 slots)
instructor_available(c_algo_cm, slot(monday,    1)).
instructor_available(c_algo_cm, slot(monday,    2)).
instructor_available(c_algo_cm, slot(wednesday, 1)).
instructor_available(c_algo_cm, slot(wednesday, 2)).
instructor_available(c_algo_cm, slot(friday,    1)).
instructor_available(c_algo_cm, slot(friday,    2)).

%% c_algo_tp_a -- Algo TP subgroup A  (2 sessions, 6 slots)
instructor_available(c_algo_tp_a, slot(monday,    5)).
instructor_available(c_algo_tp_a, slot(monday,    6)).
instructor_available(c_algo_tp_a, slot(tuesday,   1)).
instructor_available(c_algo_tp_a, slot(tuesday,   2)).
instructor_available(c_algo_tp_a, slot(thursday,  5)).
instructor_available(c_algo_tp_a, slot(thursday,  6)).

%% c_algo_tp_b -- Algo TP subgroup B  (2 sessions, 6 slots)
%% Different TA from tp_a; slots are deliberately offset to
%% allow both subgroups to run simultaneously in different labs.
instructor_available(c_algo_tp_b, slot(monday,    5)).
instructor_available(c_algo_tp_b, slot(monday,    6)).
instructor_available(c_algo_tp_b, slot(tuesday,   5)).
instructor_available(c_algo_tp_b, slot(tuesday,   6)).
instructor_available(c_algo_tp_b, slot(thursday,  1)).
instructor_available(c_algo_tp_b, slot(thursday,  2)).

%% c_gl_arch -- Architecture Logicielle  (2 sessions, 4 slots)
instructor_available(c_gl_arch, slot(monday,    3)).
instructor_available(c_gl_arch, slot(tuesday,   3)).
instructor_available(c_gl_arch, slot(wednesday, 3)).
instructor_available(c_gl_arch, slot(friday,    3)).

%% c_reseaux -- Reseaux Informatiques  (2 sessions, 5 slots)
%% Note: slots deliberately avoid tuesday/1 and tuesday/2
%% which are used by c_algo_tp_a to prevent resource deadlock.
instructor_available(c_reseaux, slot(wednesday, 1)).
instructor_available(c_reseaux, slot(wednesday, 2)).
instructor_available(c_reseaux, slot(wednesday, 5)).
instructor_available(c_reseaux, slot(thursday,  3)).
instructor_available(c_reseaux, slot(thursday,  5)).

%% c_auto -- Automatique & Controle  (2 sessions, 5 slots)
instructor_available(c_auto, slot(monday,    1)).
instructor_available(c_auto, slot(monday,    3)).
instructor_available(c_auto, slot(wednesday, 1)).
instructor_available(c_auto, slot(thursday,  5)).
instructor_available(c_auto, slot(friday,    5)).

%% c_chimie -- Chimie Organique TP  (2 sessions, 6 slots)
instructor_available(c_chimie, slot(tuesday,   5)).
instructor_available(c_chimie, slot(tuesday,   6)).
instructor_available(c_chimie, slot(thursday,  1)).
instructor_available(c_chimie, slot(thursday,  2)).
instructor_available(c_chimie, slot(friday,    5)).
instructor_available(c_chimie, slot(friday,    6)).

%% c_bio_tp -- Biologie Moleculaire TP  (1 session, 4 slots)
instructor_available(c_bio_tp, slot(wednesday, 5)).
instructor_available(c_bio_tp, slot(wednesday, 6)).
instructor_available(c_bio_tp, slot(friday,    5)).
instructor_available(c_bio_tp, slot(friday,    6)).


%% ============================================================
%%  HELPER LISTS
%% ============================================================

all_rooms([amphi_a1, amphi_a2, td_a1, td_a2, td_a3,
           it_b1, it_b2, it_b3, it_b4, td_b1,
           chem_c1, chem_c2, bio_c1, td_c1]).

all_buildings([bloc_a, bloc_b, bloc_c]).

all_days([monday, tuesday, wednesday, thursday, friday]).