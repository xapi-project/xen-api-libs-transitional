open Resources

let active = ref 0

module Counter () : sig
  type t

  val create : unit -> t

  val drop : t -> unit

  val get : t -> int
end = struct
  type t = int ref

  let create () = incr active ; ref 0

  let drop t = incr t ; decr active

  let get t = !t
end

module Inner = Counter ()

module Outer = Counter ()

module SafeInner = struct
  type 'a t = ('a, Inner.t) Scoped_dropable.t

  let create scope =
    let f () = Safe_dropable.create (module Inner) (Inner.create ()) in
    Scoped_dropable.create scope f
end

module SafeOuter = struct
  module T = struct
    type 'a t =
      { scope: (module Scope.S)
      ; inner1: 'a SafeInner.t
      ; inner2: 'a SafeInner.t
      ; c: Outer.t }

    let drop t =
      let module S = (val t.scope) in
      Outer.drop t.c ; Scope.drop S.scope
  end

  let create doraise outer_scope =
    Scoped_dropable.constructor ~drop:T.drop outer_scope
    @@ fun (module L) ->
    let inner1 = SafeInner.create L.scope in
    if doraise then failwith "TEST" ;
    let inner2 = SafeInner.create L.scope in
    let c = Outer.create () in
    { T.scope= (module L)
    ; inner1= Scoped_dropable.move_exn outer_scope inner1
    ; inner2= Scoped_dropable.move_exn outer_scope inner2
    ; c }
end

let test_nesting () =
  let outer = ref (Outer.create ()) in
  let i1 = ref (Inner.create ()) and i2 = ref (Inner.create ()) in
  Outer.drop !outer ;
  Inner.drop !i1 ;
  Inner.drop !i2 ;
  ( Scope.local
  @@ fun (module L) ->
  let o = SafeOuter.create false L.scope in
  outer := (Scoped_dropable.borrow_exn o).SafeOuter.T.c ;
  i1 :=
    (Scoped_dropable.borrow_exn o).SafeOuter.T.inner1
    |> Scoped_dropable.borrow_exn ;
  i2 :=
    (Scoped_dropable.borrow_exn o).SafeOuter.T.inner2
    |> Scoped_dropable.borrow_exn ;
  Alcotest.(check int "outer not dropped" 0 (Outer.get !outer)) ) ;
  Alcotest.(check int "outer dropped" 1 (Outer.get !outer)) ;
  Alcotest.(check int "inner1 dropped" 1 (Inner.get !i1)) ;
  Alcotest.(check int "inner2 dropped" 1 (Inner.get !i2)) ;
  Alcotest.(check int "active counters" 0 !active)

let test_nesting_raised () =
  Alcotest.(check int "active counters" 0 !active) ;
  Alcotest.check_raises "should raise" (Failure "TEST") (fun () ->
      Scope.local
      @@ fun (module L) ->
      let _ = SafeOuter.create true L.scope in
      ()) ;
  Alcotest.(check int "active counters end" 0 !active)

let tests =
  [(__LOC__, `Quick, test_nesting); (__LOC__, `Quick, test_nesting_raised)]
