module AtomicUpdate : sig
  type 'a t

  val create : 'a -> 'a t

  val update : 'a t -> ('a -> 'a) -> 'a
end = struct
  type 'a t = 'a ref ref

  let create data = ref (ref data)

  let atomic_test_and_set t old next =
    (* no allocation and function calls in this function, so the GC cannot run.
       This also means that threads are not switched, and finalisers/signal handlers are not run.
       We compare refs using physical equality, according to [Stdlib.(==)] this is well defined:
       only returns true if modifying one value would affect the other.
       For non-mutable values the comparison is implementation defined, so we couldn't have compared
       directly on the ['a] type.
    *)
    if !t == old then (
      t := next ;
      true )
    else false

  (** [update t f] updates [t] atomically with [f old] and returns the [old] value.
      [f] may be called multiple times. *)
  let rec update t f =
    (* read current state *)
    let old = !t in
    (* perform operation, this may race *)
    let next = ref (f !old) in
    if atomic_test_and_set t old next then !old
    else (* race condition detected, retry *)
      update t f
end

module SafeWork = struct
  (* can't use mutexes due to deadlocks, so use pipes *)
  let wakeup_wait, wakeup_send = Unix.pipe ()

  let to_execute = AtomicUpdate.create []

  let rec get_all () =
    let b = Bytes.create 1 in
    let (_ : int) = Unix.read wakeup_wait b 0 1 in
    (* atomically fetch the current list and replace it with the empty one *)
    let work = AtomicUpdate.update to_execute (fun _ -> []) in
    if work = [] then get_all () else List.rev work

  let add f =
    AtomicUpdate.update to_execute (fun l -> f :: l) |> ignore ;
    let (_ : int) = Unix.write_substring wakeup_send " " 0 1 in
    ()
end

let rec worker () =
  let run f = try f () with _ -> () in
  SafeWork.get_all () |> List.iter run ;
  worker ()

let start () =
  let (_ : Thread.t) = Thread.create worker () in
  ()

let finaliser f t =
  (* This makes the value live temporarily, this is allowed according to Gc.finalise docs. *)
  SafeWork.add (fun () -> f t)

let on_finalise f t = Gc.finalise (finaliser f) t

let wait () =
  let e = Event.new_channel () in
  SafeWork.add (fun () -> Event.(send e () |> sync)) ;
  Event.(receive e |> sync)
