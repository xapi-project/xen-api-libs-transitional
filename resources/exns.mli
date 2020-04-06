(** an exception with its backtrace *)
type t = exn * Printexc.raw_backtrace

val pp : t Fmt.t

(** An exception containing a list of exceptions.
    An exception printer is automatically registered
*)
exception DestructorRaised of t list

val run_all : (unit -> unit) Seq.t -> (unit, t list) result
(** [run_all l] runs all closures in [l],
    returning [Ok ()] when they all succeed and
    [Error exceptions] containing a list of all exceptions raised otherwise.
    Execution does not stop on first error.
*)

val ok_or_raise_exn : (unit, t list) result -> unit
(** [ok_or_raise_exn result] raises [DestructorRaised] containing a list of all exceptions in [result],
    if any *)
