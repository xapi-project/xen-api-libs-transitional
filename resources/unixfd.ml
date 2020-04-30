type 'a with_loc = 'a * string

module T = struct
  type t = Unix.file_descr with_loc

  let drop (t, _) = Unix.close t
end

type 'a t = ('a, T.t) Scoped_dropable.t

(* Calling functions that may take locks inside a finaliser can lead to deadlocks,
   see https://github.com/ocaml/ocaml/issues/8794 and
   https://github.com/xapi-project/xcp-idl/pull/288.

   This can be worked around by running the finaliser code on a separate thread,
   however that needs lockless data structures for safety (Mutex and Event is not safe to use
   within a finaliser). Although I have code for this it is too complex/error-prone to be used
   for code that is rarely run.

   Instead have leak tracing only for Unix file descriptors where we print errors to stderr instead
   of using a logging library.
   This is similar to what OCaml already does by default, see [Sys.enable_runtime_warnings].
*)
let finalise t =
  try
    match Scoped_dropable.borrow_opt t with
    | None ->
        ()
    | Some (fd, loc) -> (
        let enabled = Sys.runtime_warnings_enabled () in
        if enabled then
          Printf.eprintf
            "[unix_fd]: resource leak detected, allocated at %s\n%!" loc ;
        try Unix.close fd
        with e ->
          if enabled then (
            Printexc.print_backtrace stderr ;
            Printf.eprintf "[unix_fd]: close failed: %s\n%!"
              (Printexc.to_string e) ) )
  with _ ->
    (* we are inside a finaliser: do not raise here, we may end up raising at unexpected locations
     * in the program *)
    ()

let create ?(loc = "?") scope fd =
  let t =
    Scoped_dropable.create scope (fun () ->
        Safe_dropable.create (module T) (fd, loc))
  in
  Gc.finalise finalise t ; t

let pipe ?loc scope () =
  let fd1, fd2 = Unix.pipe () in
  (create ?loc scope fd1, create ?loc scope fd2)

let socketpair ?loc scope domain typ proto =
  let fd1, fd2 = Unix.socketpair domain typ proto in
  (create ?loc scope fd1, create ?loc scope fd2)

let of_fun ?loc scope f = create ?loc scope (f ())

let borrow_exn t = Scoped_dropable.borrow_exn t |> fst
