module type Dropable = sig
  type t

  val drop : t -> unit
end

exception UseAfterMoveOrRelease

type 'a dropable = (module Dropable with type t = 'a)

module T = struct
  (* a bool could've been used here to track whether we already called
   * [drop] or not but that would've kept the underlying value alive *)

  type 'a t = {v: 'a; dropable: 'a dropable}

  let create dropable v = {v; dropable}

  let get t = t.v
end

type 'a t = 'a T.t option ref

let create v = ref (Some v)

let borrow_opt t = !t

let borrow_exn t =
  match borrow_opt t with None -> raise UseAfterMoveOrRelease | Some v -> v

let move_exn t =
  let t' = borrow_exn t in
  t := None ;
  create t'

let release (type a) t =
  !t
  |> Option.iter
     @@ fun inner ->
     (* make sure [drop] cannot be called again, even if [drop] fails below *)
     t := None ;
     let module D = (val inner.T.dropable : Dropable with type t = a) in
     D.drop inner.T.v

(* give access directly to T.v, wrap the above: *)

let borrow_opt t = t |> borrow_opt |> Option.map T.get

let borrow_exn t = t |> borrow_exn |> T.get

let create dropable v = create @@ T.create dropable v

let dropable_of_drop (type a) (drop : a -> unit) =
  ( module struct
    type t = a

    let drop = drop
  end : Dropable
    with type t = a )

let of_drop drop v = create (dropable_of_drop drop) v
