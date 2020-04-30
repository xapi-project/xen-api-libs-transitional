type _ t = (unit -> unit) Stack.t option

module type S = sig
  type scope

  val scope : scope t
end

let create () =
  ( module struct
    type scope = unit

    let scope = Some (Stack.create ())
  end : S )

let create_noop () =
  ( module struct
    type scope = unit

    let scope = None
  end : S )

let add s v = Option.iter (Stack.push (fun () -> Safe_dropable.release v)) s

let drop t =
  Option.iter
    (fun t ->
       (* execute all destructors, even if one of them raises *)
       t |> Stack.to_seq |> Exns.run_all |> Exns.ok_or_raise_exn)
    t

let local f =
  let scope = create () in
  Xapi_stdext_pervasives.Pervasiveext.finally
    (fun () -> f scope)
    (fun () ->
       let module M = (val scope) in
       drop M.scope)
