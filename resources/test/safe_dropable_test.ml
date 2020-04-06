open Resources

(* TODO: look at err/warn count *)

module Counting : sig
  type t

  val create : unit -> t

  val drop : t -> unit

  val get : t -> int
end = struct
  type t = int ref

  let create () = ref 0

  let drop t = incr t

  let get t = !t
end

module SafeCounting = struct
  type t = Counting.t Safe_dropable.t

  let create () = Safe_dropable.create (module Counting) (Counting.create ())
end

let test_can_borrow t =
  let b = Safe_dropable.borrow_opt t in
  Alcotest.(check (option int) "no drop" (Some 0) (Option.map Counting.get b)) ;
  let v = Safe_dropable.borrow_exn t in
  Alcotest.(check int "no drop" 0 (Counting.get v))

let test_can_release t =
  let counter = Safe_dropable.borrow_exn t in
  Safe_dropable.release t ;
  let b = Safe_dropable.borrow_opt t in
  Alcotest.(check (option int) "dropped" None (Option.map Counting.get b)) ;
  (* here we access [counter] after [t] has been dropped.
   * In general one shouldn't do this, but for this unit test it is ok *)
  Alcotest.(check int "dropped" 1 (Counting.get counter))

let test_can_release2 t =
  let counter = Safe_dropable.borrow_exn t in
  Safe_dropable.release t ;
  Safe_dropable.release t ;
  let b = Safe_dropable.borrow_opt t in
  Alcotest.(check (option int) "dropped" None (Option.map Counting.get b)) ;
  Alcotest.(check int "dropped" 1 (Counting.get counter))

let test_can_move_release t =
  let counter = Safe_dropable.borrow_exn t in
  let t' = Safe_dropable.move_exn t in
  Alcotest.(check int "dropped" 0 (Counting.get counter)) ;
  Safe_dropable.release t' ;
  let b = Safe_dropable.borrow_opt t in
  Alcotest.(check (option int) "dropped" None (Option.map Counting.get b)) ;
  (* here we access [counter] after [t] has been dropped.
   * In general one shouldn't do this, but for this unit test it is ok *)
  Alcotest.(check int "dropped" 1 (Counting.get counter))

let test_borrow_exn_after_release t =
  Safe_dropable.release t ;
  Alcotest.check_raises "use-after-release" Safe_dropable.UseAfterMoveOrRelease
    (fun () -> Safe_dropable.borrow_exn t |> Counting.get |> ignore)

let test_move_exn_after_release t =
  Safe_dropable.release t ;
  Alcotest.check_raises "use-after-release" Safe_dropable.UseAfterMoveOrRelease
    (fun () -> Safe_dropable.move_exn t |> ignore)

let test_release_after_move t =
  let counter = Safe_dropable.borrow_exn t in
  let t' = Safe_dropable.move_exn t in
  let b = Safe_dropable.borrow_opt t in
  Alcotest.(check (option int) "moved" None (Option.map Counting.get b)) ;
  Safe_dropable.release t ;
  Alcotest.(check int "dropped" 0 (Counting.get counter)) ;
  Safe_dropable.release t' ;
  Alcotest.(check int "dropped" 1 (Counting.get counter)) ;
  let b = Safe_dropable.borrow_opt t' in
  Alcotest.(check (option int) "moved" None (Option.map Counting.get b))

let tests =
  List.map
    (fun (loc, f) ->
      let t = SafeCounting.create () in
      (loc, `Quick, fun () -> f t))
    [ (__LOC__, test_can_borrow)
    ; (__LOC__, test_can_release)
    ; (__LOC__, test_can_release2)
    ; (__LOC__, test_can_move_release)
    ; (__LOC__, test_move_exn_after_release)
    ; (__LOC__, test_release_after_move)
    ; (__LOC__, test_borrow_exn_after_release) ]
