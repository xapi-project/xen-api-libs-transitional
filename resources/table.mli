type ('a, 'b, 'c) t
module Global: Scope.S
val create : int -> ('a, 'b, 'c) t
val clear: ('a, 'b, 'c) t -> unit
val reset: ('a, 'b, 'c) t -> unit
val copy: ('a, 'b, 'c) t -> ('a, 'b, 'c) t
val add: ('a, 'b, 'c) t -> 'b -> (_, 'c) Scoped_dropable.t -> unit
val replace: ('a, 'b, 'c) t -> 'b -> (_, 'c) Scoped_dropable.t -> unit
val find: ('a, 'b, 'c) t -> 'b -> (Global.scope, 'c) Scoped_dropable.t
val find_opt: ('a, 'b, 'c) t -> 'b -> (Global.scope, 'c) Scoped_dropable.t option
val find_all: ('a, 'b, 'c) t -> 'b -> (Global.scope, 'c) Scoped_dropable.t list
val mem: ('a, 'b, 'c) t -> 'b -> bool
val remove: ('a, 'b, 'c) t -> 'b -> unit
val iter: ('b -> (Global.scope, 'c) Scoped_dropable.t -> unit) -> ('a, 'b, 'c) t -> unit
val filter_map_inplace: ('b -> (Global.scope, 'c) Scoped_dropable.t -> (Global.scope, 'c) Scoped_dropable.t option) -> ('a, 'b, 'c) t -> unit
val fold: ('b -> (Global.scope, 'c) Scoped_dropable.t -> 'd -> 'd) -> ('a, 'b, 'c) t -> 'd -> 'd
val length: ('a, 'b, 'c) t -> int
val stats: ('a, 'b, 'c) t -> Hashtbl.statistics
val to_seq: ('a, 'b, 'c) t -> ('b * (Global.scope, 'c) Scoped_dropable.t) Seq.t
val to_seq_keys: ('a, 'b, 'c) t -> 'b Seq.t
val to_seq_values: ('a, 'b, 'c) t -> (Global.scope, 'c) Scoped_dropable.t Seq.t

val add_seq: ('a, 'b, 'c) t -> ('b * (_, 'c) Scoped_dropable.t) Seq.t -> unit
val replace_seq: ('a, 'b, 'c) t -> ('b * (_, 'c) Scoped_dropable.t) Seq.t -> unit
val of_seq: ('b * (_, 'c) Scoped_dropable.t) Seq.t -> ('a, 'b, 'c) t

val find_and_move_exn: 'a Scope.t -> (_, 'b, 'c) t -> 'b -> ('a, 'c) Scoped_dropable.t
