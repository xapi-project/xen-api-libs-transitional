module T : sig
  type t
end

type 'a t = ('a, T.t) Scoped_dropable.t

val pipe : ?loc:string -> 'a Scope.t -> unit -> 'a t * 'a t

val borrow_exn: 'a t -> Unix.file_descr

val socketpair :
     ?loc:string
  -> 'a Scope.t
  -> Unix.socket_domain
  -> Unix.socket_type
  -> int
  -> 'a t * 'a t

val of_fun : ?loc:string -> 'a Scope.t -> (unit -> Unix.file_descr) -> 'a t
