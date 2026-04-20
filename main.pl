%% ============================================================
%%  main.pl -- INSAT Schedule Planner Entry Point
%%
%%  Quick start (SWI-Prolog REPL):
%%    ?- [main].           %% load all modules
%%    ?- run.              %% find ONE valid schedule (fast)
%%    ?- run_optimal.      %% find BEST schedule via best-of-200
%%    ?- go.               %% alias for run/0
%% ============================================================

:- [facts, constraints, scheduler, optimization].
:- use_module(library(http/json)).



%% ============================================================
%%  PRETTY PRINTING
%% ============================================================

period_label(1, '08h00-09h30').
period_label(2, '09h30-11h00').
period_label(3, '11h00-12h30').
period_label(5, '14h00-15h30').
period_label(6, '15h30-17h00').
period_label(7, '17h00-18h30').

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
%%  run/0 -- First valid schedule (DFS, instant)
%% ============================================================

run :-
    div,
    write('  INSAT Timetable -- finding first valid schedule'), nl,
    div,
    (   schedule(Schedule)
    ->  nl, header,
        print_schedule(Schedule),
        div,
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
    ->  nl,
        format("  BEST SCHEDULE (score ~4f, sampled ~w candidates)~n", [Score, N]),
        header,
        print_schedule(Best),
        div,
        print_metrics(Best), nl
    ;   write('  No valid schedule found.'), nl
    ).


%% Aliases
go         :- run.
go_optimal :- run_optimal.


%% ============================================================
%%  HTML GENERATION
%% ============================================================

%% Converts a schedule term into a Prolog dict suitable for library(http/json).
assign_to_dict(assign(Course, Session, Room, slot(Day, Period)),
               json{course:Course, session:Session, room:Room, day:Day, period:Period}).

%% Generates JSON string from schedule.
schedule_to_json(Schedule, JsonString) :-
    maplist(assign_to_dict, Schedule, Dicts),
    with_output_to(string(JsonString), json_write_dict(current_output, Dicts, [width(0)])).

%% Replaces the schedule in the HTML template.
replace_schedule(Template, JsonLine, Result) :-
    sub_string(Template, BeforeLen, _, _, "const SCHEDULE = ["),
    sub_string(Template, 0, BeforeLen, _, BeforeText),
    sub_string(Template, BeforeLen, _, 0, RestText),
    once(sub_string(RestText, _, 2, AfterLen, "];")),
    sub_string(RestText, _, AfterLen, 0, AfterText),
    string_concat(BeforeText, "const SCHEDULE = ", T1),
    string_concat(T1, JsonLine, T2),
    string_concat(T2, ";", T3),
    string_concat(T3, AfterText, Result).

%% Main HTML generation predicate.
generate_html_schedule(Schedule, Filename) :-
    (   read_file_to_string('timetable.html', Template, [])
    ->  schedule_to_json(Schedule, Json),
        (   replace_schedule(Template, Json, FinalHTML)
        ->  open(Filename, write, Out),
            write(Out, FinalHTML),
            close(Out),
            format("  Success! HTML schedule generated: ~w~n", [Filename])
        ;   write("  Error: Could not find SCHEDULE block in template.~n")
        )
    ;   write("  Error: Could not read timetable.html. Ensure it exists in the current directory.~n")
    ).

%% Optimized run for HTML output.
run_html :-
    div,
    write('  INSAT Timetable -- finding optimized schedule for HTML'), nl,
    div,
    N = 200,
    (   best_of_n(N, Best, Score)
    ->  nl,
        format("  BEST SCHEDULE (score ~4f) found.~n", [Score]),
        generate_html_schedule(Best, 'schedule_output.html'),
        div,
        print_metrics(Best), nl
    ;   write('  No valid schedule found.'), nl
    ).

%% Alias
go_html :- run_html.