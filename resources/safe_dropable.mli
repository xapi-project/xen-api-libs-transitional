(** At the lowest level we have resources with an associated destructor.
    Using Rust terminology we call this 'drop': typically closing, deallocating, or otherwise
    releasing a resource such as a file descriptor or a lock.
    Also called a destructor in other languages.
*)
module type Dropable = sig
  (** a resource *)
  type t

  val drop : t -> unit
  (** [drop resource] releases [resource]. E.g. close a file, unlock a mutex, etc.
      Calling this multiple times may result in undefined behaviour.
      Using [t] after it has been [drop]ed can also result in undefined behaviour
      (e.g. file descriptor could've been already reused for another file)
  *)
end

(** Trying to call [borrow_exn] after [move] or [release] has already been performed. *)
exception UseAfterMoveOrRelease

(** a type with a [drop] operation *)
type 'a dropable = (module Dropable with type t = 'a)

(** A type with a [release] operation that can be called at most once.
    Also called an affine type.
*)
type 'a t

val create : 'a dropable -> 'a -> 'a t
(** [create v] wraps [v] with safe [drop] semantics *)

val of_drop : ('a -> unit) -> 'a -> 'a t
(** [of_drop drop v] is like [create v] using [drop] as the destructor *)

val borrow_opt : 'a t -> 'a option
(** [borrow_opt t] returns the underlying value of [t] if a [release] hasn't been performed.
*)

val borrow_exn : 'a t -> 'a
(** [borrow_exn t] is like [borrow_opt], but raises [UseAfterMoveRelease] on failure. *)

val move_exn : 'a t -> 'a t
(** [move_exn t] creates a shallow copy of [t].
 * Any further operation on [t] raises [UseAfterMoveOrRelease] *)

val release : 'a t -> unit
(** [release t] executes [drop] on the underlying value of [t] at most once.
    The original [t] drops any references to its underlying value.

    Any further [borrow_*] operation on [t] will fail.
    Any further [release] operation on [t] will be a no-op.
    Exceptions raised by [drop] are passed-through.
*)
