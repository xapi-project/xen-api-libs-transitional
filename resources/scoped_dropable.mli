type ('scope, 'raw) t

val create :
  'scope Scope.t -> (unit -> 'raw Safe_dropable.t) -> ('scope, 'raw) t

val borrow_opt : ('scope, 'raw) t -> 'raw option

val borrow_exn : ('scope, 'raw) t -> 'raw

val move_exn : 'b Scope.t -> ('a, 'raw) t -> ('b, 'raw) t

val release : ('scope, _) t -> unit

val constructor :
  'a Scope.t -> drop:('b -> unit) -> ((module Scope.S) -> 'b) -> ('a, 'b) t
