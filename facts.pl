%% ============================================================
%%  facts.pl  -- INSAT Campus Knowledge Base
%%  Institut National des Sciences Appliquees et de Technologie
%%  Centre Urbain Nord, BP 676 -- 1080 Tunis Cedex
%%
%%  Models a realistic weekly schedule for two departments:
%%    * DGIM  -- Genie Informatique et Mathematiques (MPI track)
%%    * GBC   -- Genie Biologique et Chimique        (CBA track)
%%
%%  Structure:
%%    - 18 courses, 34 weekly sessions total
%%    - 14 rooms across 3 building blocs
%%    - 5-day week, 6 usable time slots per day (lunch excluded)
%%
%%  REAL-WORLD CONTEXT
%%  ------------------
%%  INSAT (founded 1992, affiliated with Universite de Carthage)
%%  has ~2260 students, 166 instructors, and offers 5-year
%%  engineering programmes in two main tracks:
%%    MPI  -- Mathematiques, Physique, Informatique  (Year 1)
%%    CBA  -- Chimie, Biologie Appliquees            (Year 1)
%%
%%  Both tracks follow the same structure:
%%    - Combined cohort in amphitheatre for CM (cours magistral)
%%    - Split into subgroups A/B for TD/TP sessions
%%
%%  MPI COURSES (Year 1)
%%  --------------------
%%    Algorithmique         CM  +  TP  (subgroups A & B)
%%    Analyse Mathematique  CM  +  TD  (subgroups A & B)
%%    Algebre Lineaire      CM  +  TD  (subgroups A & B)
%%
%%  CBA COURSES (Year 1)
%%  --------------------
%%    Chimie Generale       CM  +  TP  (subgroups A & B)
%%    Biologie Cellulaire   CM  +  TP  (subgroups A & B)
%%    Mathematiques (CBA)   CM  +  TD  (subgroups A & B)
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
%%  Both tracks mirror the same structure:
%%    *_cm   -- full cohort, amphitheatre CM sessions
%%    *a     -- subgroup A, TD / TP sessions
%%    *b     -- subgroup B, TD / TP sessions
%% ============================================================

%% MPI Year-1
group_size(g_mpi1_cm,  80).   %% MPI Year-1 combined  (amphitheatre CM)
group_size(g_mpi1a,    40).   %% MPI Year-1 subgroup A  (TD / TP)
group_size(g_mpi1b,    40).   %% MPI Year-1 subgroup B  (TD / TP)

%% CBA Year-1
group_size(g_cba1_cm,  60).   %% CBA Year-1 combined  (amphitheatre CM)
group_size(g_cba1a,    30).   %% CBA Year-1 subgroup A  (TD / TP)
group_size(g_cba1b,    30).   %% CBA Year-1 subgroup B  (TD / TP)


%% ============================================================
%%  COURSES
%%  course(Id, Group, SessionsPerWeek, Duration, EquipNeeded)
%%
%%  Duration = 1 for all courses (one 90-min slot per session).
%%  This matches the standard INSAT slot grid.
%%
%%  Equipment atoms: amphi_proj | standard | it_lab |
%%                   chem_lab   | bio_lab
%%
%%  DGIM / MPI track -----------------------------------------
%%    c_algo_cm       Algorithmique             -- CM
%%    c_algo_tp_a     Algorithmique             -- TP subgroup A
%%    c_algo_tp_b     Algorithmique             -- TP subgroup B
%%    c_analyse_cm    Analyse Mathematique      -- CM
%%    c_analyse_td_a  Analyse Mathematique      -- TD subgroup A
%%    c_analyse_td_b  Analyse Mathematique      -- TD subgroup B
%%    c_algebre_cm    Algebre Lineaire          -- CM
%%    c_algebre_td_a  Algebre Lineaire          -- TD subgroup A
%%    c_algebre_td_b  Algebre Lineaire          -- TD subgroup B
%%
%%  GBC / CBA track ------------------------------------------
%%    c_chimie_cm      Chimie Generale          -- CM
%%    c_chimie_tp_a    Chimie Generale          -- TP subgroup A
%%    c_chimie_tp_b    Chimie Generale          -- TP subgroup B
%%    c_bio_cm         Biologie Cellulaire      -- CM
%%    c_bio_tp_a       Biologie Cellulaire      -- TP subgroup A
%%    c_bio_tp_b       Biologie Cellulaire      -- TP subgroup B
%%    c_maths_cba_cm   Mathematiques (CBA)      -- CM
%%    c_maths_cba_td_a Mathematiques (CBA)      -- TD subgroup A
%%    c_maths_cba_td_b Mathematiques (CBA)      -- TD subgroup B
%% ============================================================

%% --- MPI track ---
course(c_algo_cm,        g_mpi1_cm, 2, 1, amphi_proj).
course(c_algo_tp_a,      g_mpi1a,   2, 1, it_lab).
course(c_algo_tp_b,      g_mpi1b,   2, 1, it_lab).
course(c_analyse_cm,     g_mpi1_cm, 2, 1, amphi_proj).
course(c_analyse_td_a,   g_mpi1a,   2, 1, standard).
course(c_analyse_td_b,   g_mpi1b,   2, 1, standard).
course(c_algebre_cm,     g_mpi1_cm, 2, 1, amphi_proj).
course(c_algebre_td_a,   g_mpi1a,   2, 1, standard).
course(c_algebre_td_b,   g_mpi1b,   2, 1, standard).

%% --- CBA track ---
course(c_chimie_cm,      g_cba1_cm, 2, 1, amphi_proj).
course(c_chimie_tp_a,    g_cba1a,   2, 1, chem_lab).
course(c_chimie_tp_b,    g_cba1b,   2, 1, chem_lab).
course(c_bio_cm,         g_cba1_cm, 2, 1, amphi_proj).
course(c_bio_tp_a,       g_cba1a,   1, 1, bio_lab).
course(c_bio_tp_b,       g_cba1b,   1, 1, bio_lab).
course(c_maths_cba_cm,   g_cba1_cm, 2, 1, amphi_proj).
course(c_maths_cba_td_a, g_cba1a,   2, 1, standard).
course(c_maths_cba_td_b, g_cba1b,   2, 1, standard).


%% ============================================================
%%  ROOMS
%%  room(Id, Capacity, Equipment, Building)
%%
%%  Bloc A -- Main academic building (amphitheatres + TD rooms)
%%            Serves both tracks for CM and MPI TD sessions.
%%  Bloc B -- Informatique building  (IT labs)
%%            Dedicated to MPI TP (Algorithmique).
%%  Bloc C -- Sciences building      (chem labs + bio lab + TDs)
%%            Dedicated to CBA TP and TD sessions.
%% ============================================================

%% Bloc A
room(amphi_a1, 200, amphi_proj, bloc_a).   %% Grand amphitheatre (MPI CM)
room(amphi_a2, 150, amphi_proj, bloc_a).   %% Amphitheatre B     (CBA CM)
room(td_a1,     40, standard,   bloc_a).   %% Salle TD 1
room(td_a2,     40, standard,   bloc_a).   %% Salle TD 2
room(td_a3,     40, standard,   bloc_a).   %% Salle TD 3

%% Bloc B
room(it_b1, 40, it_lab, bloc_b).   %% Labo Informatique 1
room(it_b2, 40, it_lab, bloc_b).   %% Labo Informatique 2
room(it_b3, 40, it_lab, bloc_b).   %% Labo Informatique 3
room(it_b4, 40, it_lab, bloc_b).   %% Labo Informatique 4

%% Bloc C
room(chem_c1, 30, chem_lab, bloc_c).   %% Labo Chimie 1
room(chem_c2, 30, chem_lab, bloc_c).   %% Labo Chimie 2
room(bio_c1,  30, bio_lab,  bloc_c).   %% Labo Biologie Cellulaire
room(td_c1,   35, standard, bloc_c).   %% Salle TD Sciences 1
room(td_c2,   35, standard, bloc_c).   %% Salle TD Sciences 2


%% ============================================================
%%  ENERGY COST
%%  energy_cost(RoomId, UnitsPerSlot)
%%
%%  Amphitheatres and specialist labs consume more energy.
%%  Standard TD rooms are cheap; IT labs moderate.
%% ============================================================

energy_cost(amphi_a1, 15).
energy_cost(amphi_a2, 12).
energy_cost(td_a1,     3).
energy_cost(td_a2,     3).
energy_cost(td_a3,     3).
energy_cost(it_b1,     8).
energy_cost(it_b2,     8).
energy_cost(it_b3,     8).
energy_cost(it_b4,     8).
energy_cost(chem_c1,  10).
energy_cost(chem_c2,  10).
energy_cost(bio_c1,    8).
energy_cost(td_c1,     3).
energy_cost(td_c2,     3).


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
%%
%%  Slot windows are staggered between courses that share the
%%  same group, giving the constraint solver maximum freedom
%%  while reflecting realistic instructor teaching loads.
%% ============================================================

%% ----------------------------------------------------------
%%  MPI track -- CM sessions (amphitheatre)
%% ----------------------------------------------------------

%% c_algo_cm -- Algorithmique CM  (2 sessions, 6 slots)
%%   Instructor A: Mon/Wed/Fri mornings
instructor_available(c_algo_cm, slot(monday,    1)).
instructor_available(c_algo_cm, slot(monday,    2)).
instructor_available(c_algo_cm, slot(wednesday, 1)).
instructor_available(c_algo_cm, slot(wednesday, 2)).
instructor_available(c_algo_cm, slot(friday,    1)).
instructor_available(c_algo_cm, slot(friday,    2)).

%% c_analyse_cm -- Analyse Mathematique CM  (2 sessions, 6 slots)
%%   Instructor B: Tue/Thu mornings + Wed/Fri mid-morning
instructor_available(c_analyse_cm, slot(tuesday,   1)).
instructor_available(c_analyse_cm, slot(tuesday,   2)).
instructor_available(c_analyse_cm, slot(wednesday, 3)).
instructor_available(c_analyse_cm, slot(thursday,  1)).
instructor_available(c_analyse_cm, slot(thursday,  2)).
instructor_available(c_analyse_cm, slot(friday,    3)).

%% c_algebre_cm -- Algebre Lineaire CM  (2 sessions, 6 slots)
%%   Instructor C: afternoons and Thu/Fri late slots
instructor_available(c_algebre_cm, slot(tuesday,   3)).
instructor_available(c_algebre_cm, slot(wednesday, 5)).
instructor_available(c_algebre_cm, slot(thursday,  3)).
instructor_available(c_algebre_cm, slot(thursday,  5)).
instructor_available(c_algebre_cm, slot(friday,    5)).
instructor_available(c_algebre_cm, slot(friday,    6)).

%% ----------------------------------------------------------
%%  MPI track -- Subgroup A  (TP/TD)
%% ----------------------------------------------------------

%% c_algo_tp_a -- Algorithmique TP subgroup A  (2 sessions, 6 slots)
%%   TA-A: Mon/Tue/Thu afternoons
instructor_available(c_algo_tp_a, slot(monday,    5)).
instructor_available(c_algo_tp_a, slot(monday,    6)).
instructor_available(c_algo_tp_a, slot(tuesday,   1)).
instructor_available(c_algo_tp_a, slot(tuesday,   2)).
instructor_available(c_algo_tp_a, slot(thursday,  5)).
instructor_available(c_algo_tp_a, slot(thursday,  6)).

%% c_analyse_td_a -- Analyse TD subgroup A  (2 sessions, 6 slots)
%%   Instructor B (same as CM, different slots): Tue/Wed/Thu
instructor_available(c_analyse_td_a, slot(tuesday,   5)).
instructor_available(c_analyse_td_a, slot(tuesday,   6)).
instructor_available(c_analyse_td_a, slot(wednesday, 1)).
instructor_available(c_analyse_td_a, slot(wednesday, 2)).
instructor_available(c_analyse_td_a, slot(thursday,  1)).
instructor_available(c_analyse_td_a, slot(thursday,  2)).

%% c_algebre_td_a -- Algebre TD subgroup A  (2 sessions, 6 slots)
%%   Instructor C (same as CM): Mon/Wed/Fri mid-morning & afternoon
instructor_available(c_algebre_td_a, slot(monday,    3)).
instructor_available(c_algebre_td_a, slot(wednesday, 3)).
instructor_available(c_algebre_td_a, slot(wednesday, 5)).
instructor_available(c_algebre_td_a, slot(thursday,  3)).
instructor_available(c_algebre_td_a, slot(friday,    3)).
instructor_available(c_algebre_td_a, slot(friday,    5)).

%% ----------------------------------------------------------
%%  MPI track -- Subgroup B  (TP/TD)
%% ----------------------------------------------------------

%% c_algo_tp_b -- Algorithmique TP subgroup B  (2 sessions, 6 slots)
%%   TA-B: offset from TA-A to allow parallel lab sessions
instructor_available(c_algo_tp_b, slot(monday,    5)).
instructor_available(c_algo_tp_b, slot(monday,    6)).
instructor_available(c_algo_tp_b, slot(tuesday,   5)).
instructor_available(c_algo_tp_b, slot(tuesday,   6)).
instructor_available(c_algo_tp_b, slot(thursday,  1)).
instructor_available(c_algo_tp_b, slot(thursday,  2)).

%% c_analyse_td_b -- Analyse TD subgroup B  (2 sessions, 6 slots)
%%   Different TA from td_a: Mon/Wed/Fri
instructor_available(c_analyse_td_b, slot(monday,    1)).
instructor_available(c_analyse_td_b, slot(monday,    2)).
instructor_available(c_analyse_td_b, slot(wednesday, 5)).
instructor_available(c_analyse_td_b, slot(wednesday, 6)).
instructor_available(c_analyse_td_b, slot(friday,    1)).
instructor_available(c_analyse_td_b, slot(friday,    5)).

%% c_algebre_td_b -- Algebre TD subgroup B  (2 sessions, 6 slots)
%%   Different TA from td_a: Tue/Wed/Thu/Fri mid-morning
instructor_available(c_algebre_td_b, slot(monday,    3)).
instructor_available(c_algebre_td_b, slot(tuesday,   3)).
instructor_available(c_algebre_td_b, slot(wednesday, 3)).
instructor_available(c_algebre_td_b, slot(thursday,  3)).
instructor_available(c_algebre_td_b, slot(friday,    3)).
instructor_available(c_algebre_td_b, slot(friday,    6)).

%% ----------------------------------------------------------
%%  CBA track -- CM sessions (amphitheatre)
%% ----------------------------------------------------------

%% c_chimie_cm -- Chimie Generale CM  (2 sessions, 6 slots)
%%   Instructor D: Mon/Tue mornings + Fri mornings
instructor_available(c_chimie_cm, slot(monday,    1)).
instructor_available(c_chimie_cm, slot(monday,    2)).
instructor_available(c_chimie_cm, slot(tuesday,   3)).
instructor_available(c_chimie_cm, slot(wednesday, 1)).
instructor_available(c_chimie_cm, slot(friday,    1)).
instructor_available(c_chimie_cm, slot(friday,    2)).

%% c_bio_cm -- Biologie Cellulaire CM  (2 sessions, 6 slots)
%%   Instructor E: Mon/Wed afternoons + Thu/Fri afternoon
instructor_available(c_bio_cm, slot(monday,    5)).
instructor_available(c_bio_cm, slot(monday,    6)).
instructor_available(c_bio_cm, slot(wednesday, 5)).
instructor_available(c_bio_cm, slot(wednesday, 6)).
instructor_available(c_bio_cm, slot(thursday,  5)).
instructor_available(c_bio_cm, slot(friday,    5)).

%% c_maths_cba_cm -- Mathematiques (CBA) CM  (2 sessions, 6 slots)
%%   Instructor F: Tue/Wed/Thu mornings
instructor_available(c_maths_cba_cm, slot(tuesday,   1)).
instructor_available(c_maths_cba_cm, slot(tuesday,   2)).
instructor_available(c_maths_cba_cm, slot(wednesday, 3)).
instructor_available(c_maths_cba_cm, slot(thursday,  1)).
instructor_available(c_maths_cba_cm, slot(thursday,  3)).
instructor_available(c_maths_cba_cm, slot(friday,    3)).

%% ----------------------------------------------------------
%%  CBA track -- Subgroup A  (TP/TD)
%% ----------------------------------------------------------

%% c_chimie_tp_a -- Chimie TP subgroup A  (2 sessions, 6 slots)
%%   Lab demonstrator A: Tue/Thu/Fri afternoons
instructor_available(c_chimie_tp_a, slot(tuesday,   5)).
instructor_available(c_chimie_tp_a, slot(tuesday,   6)).
instructor_available(c_chimie_tp_a, slot(thursday,  1)).
instructor_available(c_chimie_tp_a, slot(thursday,  2)).
instructor_available(c_chimie_tp_a, slot(friday,    5)).
instructor_available(c_chimie_tp_a, slot(friday,    6)).

%% c_bio_tp_a -- Biologie TP subgroup A  (1 session, 4 slots)
%%   Lab demonstrator A (bio): Wed/Thu afternoons
instructor_available(c_bio_tp_a, slot(wednesday, 5)).
instructor_available(c_bio_tp_a, slot(wednesday, 6)).
instructor_available(c_bio_tp_a, slot(thursday,  5)).
instructor_available(c_bio_tp_a, slot(friday,    6)).

%% c_maths_cba_td_a -- Mathematiques TD subgroup A  (2 sessions, 6 slots)
%%   Instructor F (same as CM): Mon/Tue/Wed/Fri mid-morning
instructor_available(c_maths_cba_td_a, slot(monday,    3)).
instructor_available(c_maths_cba_td_a, slot(tuesday,   3)).
instructor_available(c_maths_cba_td_a, slot(wednesday, 3)).
instructor_available(c_maths_cba_td_a, slot(thursday,  6)).
instructor_available(c_maths_cba_td_a, slot(friday,    3)).
instructor_available(c_maths_cba_td_a, slot(friday,    6)).

%% ----------------------------------------------------------
%%  CBA track -- Subgroup B  (TP/TD)
%% ----------------------------------------------------------

%% c_chimie_tp_b -- Chimie TP subgroup B  (2 sessions, 6 slots)
%%   Different demonstrator from tp_a: Mon/Tue/Wed/Thu/Fri
instructor_available(c_chimie_tp_b, slot(monday,    3)).
instructor_available(c_chimie_tp_b, slot(tuesday,   3)).
instructor_available(c_chimie_tp_b, slot(wednesday, 3)).
instructor_available(c_chimie_tp_b, slot(thursday,  5)).
instructor_available(c_chimie_tp_b, slot(thursday,  6)).
instructor_available(c_chimie_tp_b, slot(friday,    3)).

%% c_bio_tp_b -- Biologie TP subgroup B  (1 session, 4 slots)
%%   Different demonstrator from tp_a
instructor_available(c_bio_tp_b, slot(wednesday, 5)).
instructor_available(c_bio_tp_b, slot(wednesday, 6)).
instructor_available(c_bio_tp_b, slot(thursday,  6)).
instructor_available(c_bio_tp_b, slot(friday,    5)).

%% c_maths_cba_td_b -- Mathematiques TD subgroup B  (2 sessions, 6 slots)
%%   Different TA from td_a: Mon/Tue mornings + Wed/Thu
instructor_available(c_maths_cba_td_b, slot(monday,    1)).
instructor_available(c_maths_cba_td_b, slot(monday,    2)).
instructor_available(c_maths_cba_td_b, slot(tuesday,   1)).
instructor_available(c_maths_cba_td_b, slot(tuesday,   2)).
instructor_available(c_maths_cba_td_b, slot(wednesday, 2)).
instructor_available(c_maths_cba_td_b, slot(thursday,  2)).


%% ============================================================
%%  HELPER LISTS
%% ============================================================

all_courses([c_algo_cm,      c_algo_tp_a,      c_algo_tp_b,
             c_analyse_cm,   c_analyse_td_a,   c_analyse_td_b,
             c_algebre_cm,   c_algebre_td_a,   c_algebre_td_b,
             c_chimie_cm,    c_chimie_tp_a,    c_chimie_tp_b,
             c_bio_cm,       c_bio_tp_a,       c_bio_tp_b,
             c_maths_cba_cm, c_maths_cba_td_a, c_maths_cba_td_b]).

all_groups([g_mpi1_cm, g_mpi1a, g_mpi1b,
            g_cba1_cm, g_cba1a, g_cba1b]).

all_rooms([amphi_a1, amphi_a2, td_a1, td_a2, td_a3,
           it_b1, it_b2, it_b3, it_b4,
           chem_c1, chem_c2, bio_c1, td_c1, td_c2]).

all_buildings([bloc_a, bloc_b, bloc_c]).

all_days([monday, tuesday, wednesday, thursday, friday]).