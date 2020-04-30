type +'a t

module type S = sig
  type scope

  val scope : scope t
end

val create : unit -> (module S)

(* for internal use only *)
val create_noop: unit -> (module S)

val add : 'a t -> 'b Safe_dropable.t -> unit

val drop : 'a t -> unit

val local : ((module S) -> 'a) -> 'a
