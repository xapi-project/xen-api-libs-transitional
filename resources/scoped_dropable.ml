type ('scope, 'raw) t = 'raw Safe_dropable.t

let create scope f =
  let v = f () in
  Scope.add scope v ; v

let borrow_opt t = Safe_dropable.borrow_opt t

let borrow_exn t = Safe_dropable.borrow_exn t

let release t = Safe_dropable.release t

let move_exn scope t =
  let t = Safe_dropable.move_exn t in
  Scope.add scope t ; t

let constructor outer_scope ~drop f =
  Scope.local
  @@ fun (module L) ->
  move_exn outer_scope
    ( create L.scope
    @@ fun () -> f (module L : Scope.S) |> Safe_dropable.of_drop drop )
