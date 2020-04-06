type t = exn * Printexc.raw_backtrace

let pp = Fmt.exn_backtrace

let wrap f =
  try Ok (f ())
  with e ->
    let bt = Printexc.get_raw_backtrace () in
    Error (e, bt)

exception DestructorRaised of t list

let pp_destructor_raised =
  Fmt.(const string "DestructorRaised: " ++ list pp) |> Fmt.vbox

let () =
  Printexc.register_printer (function
    | DestructorRaised l ->
        Some (Fmt.to_to_string pp_destructor_raised l)
    | Fun.Finally_raised e ->
        Some ("Finally raised: " ^ Printexc.to_string e)
    | _ ->
        None)

let extract_error = function Ok () -> None | Error e -> Some e

let run_all seq =
  match seq |> Seq.map wrap |> Seq.filter_map extract_error |> List.of_seq with
  | [] ->
      Ok ()
  | exns ->
      Error exns

let ok_or_raise_exn = function
  | Ok () ->
      ()
  | Error exns ->
      raise (DestructorRaised exns)
