module Global = (val Scope.create_noop ())
type ('a, 'b, 'c) t = ('b, (Global.scope, 'c) Scoped_dropable.t) Hashtbl.t


let create n = Hashtbl.create n

let release t =
  Hashtbl.iter (fun _ v -> Scoped_dropable.release v) t

let clear t =
  release t;
  Hashtbl.clear t

let reset t =
  release t;
  Hashtbl.reset t

let copy = Hashtbl.copy

let add (t:('a, 'b, 'c) t) k v =
  Hashtbl.add t k (Scoped_dropable.move_exn Global.scope v)

let find = Hashtbl.find
let find_opt = Hashtbl.find_opt
let find_all = Hashtbl.find_all
let mem = Hashtbl.mem

let remove t k =
  Option.iter Scoped_dropable.release (find_opt t k);
  Hashtbl.remove t k

let replace t k v =
  Option.iter Scoped_dropable.release (find_opt t k);
  Hashtbl.replace t k (Scoped_dropable.move_exn Global.scope v)

let iter = Hashtbl.iter
let filter_map_inplace f t =
  Hashtbl.filter_map_inplace (fun k v ->
      let r = f k v in
      if r = None then Scoped_dropable.release v;
      r) t

let fold = Hashtbl.fold
let length = Hashtbl.length
let stats = Hashtbl.stats
let to_seq = Hashtbl.to_seq
let to_seq_keys = Hashtbl.to_seq_keys
let to_seq_values = Hashtbl.to_seq_values

let add_seq t s = Seq.iter (fun (k,v) -> add t k v) s
let replace_seq t s = Seq.iter (fun (k,v) -> replace t k v) s

let of_seq s =
  let t = create 7 in
  replace_seq t s;
  t

let find_and_move_exn scope t k =
  Scoped_dropable.move_exn scope (find t k)
