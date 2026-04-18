%% main.pl — Entry Point
:- [facts, constraints, scheduler, optimization].

%% Pretty-print a schedule
print_schedule([]).
print_schedule([assign(Course, Session, Room, Slot) | Rest]) :-
    format("  ~w session ~w → room ~w at ~w~n",
           [Course, Session, Room, Slot]),
    print_schedule(Rest).

%% Main query: find and display the best schedule
run :-
    write("Searching for optimal schedule..."), nl,
    (   optimal_schedule(Best)
    ->  write("=== OPTIMAL SCHEDULE ==="), nl,
        print_schedule(Best), nl,
        combined_score(Best, Score),
        format("Combined score: ~2f~n", [Score])
    ;   write("No valid schedule found."), nl
    ).