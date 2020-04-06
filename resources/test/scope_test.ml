open Resources

let test_scope_noop () =
  let module L = (val Scope.create ()) in
  Scope.drop L.scope

let on_drop f =
  Safe_dropable.create
    ( module struct
      type t = unit

      let drop = f
    end )
    ()

let test_scope_cleanup () =
  let order = ref [] in
  let f idx = on_drop (fun () -> order := idx :: !order) in
  ( Scope.local
  @@ fun (module L) ->
  Scope.add L.scope (f 4) ;
  Scope.add L.scope (f 3) ;
  ( Scope.local
  @@ fun (module L) ->
  Scope.add L.scope (f 1) ;
  Scope.add L.scope (f 0) ) ;
  (* scope ended, destructors for 0 and 1 run first *)
  (* then the destructor for 2, and then the things previously on stack *)
  Scope.add L.scope (f 2) ) ;
  order := List.rev !order ;
  Alcotest.(check (list int) "order of execution" [0; 1; 2; 3; 4] !order)

let test_scope_cleanup_exn () =
  let order = ref [] in
  let f idx = on_drop (fun () -> order := idx :: !order) in
  Alcotest.(
    check_raises "raises" (Failure "TEST") (fun () ->
        Scope.local
        @@ fun (module L) ->
        Scope.add L.scope (f 2) ;
        Scope.add L.scope (f 1) ;
        Scope.add L.scope (f 0) ;
        failwith "TEST")) ;
  order := List.rev !order ;
  Alcotest.(check (list int) "order of execution" [0; 1; 2] !order)

let tests =
  [ (__LOC__, `Quick, test_scope_noop)
  ; (__LOC__, `Quick, test_scope_cleanup)
  ; (__LOC__, `Quick, test_scope_cleanup_exn) ]
