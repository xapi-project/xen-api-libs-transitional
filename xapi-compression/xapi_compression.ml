module type ALGORITHM = sig
  val executable : string
end

module D = Debug.Make (struct let name = "xapi_compression" end)

open D

let finally = Xapi_stdext_pervasives.Pervasiveext.finally

module Make (Algorithm : ALGORITHM) = struct
  let available () = Sys.file_exists Algorithm.executable

  type zcat_mode = Compress | Decompress

  type input_type =
    | Active
        (** we provide a function which writes into the compressor and a fd output *)
    | Passive
        (** we provide an fd input and a function which reads from the compressor *)

  (* start cmd with lowest priority so that it doesn't
     use up all cpu resources in dom0
  *)
  let lower_priority cmd args =
    let ionice = "/usr/bin/ionice" in
    let ionice_args = ["-c"; "3"] in
    (*io idle*)
    let nice = "/bin/nice" in
    let nice_args = ["-n"; "19"] in
    (*lowest priority*)
    let extra_args = nice_args @ [ionice] @ ionice_args in
    let new_cmd = nice in
    let new_args = extra_args @ [cmd] @ args in
    (new_cmd, new_args)

  (** Runs a zcat process which is either:
      i) a compressor; or (ii) a decompressor
      and which has either
      i) an active input (ie a function and a pipe) + passive output (fd); or
      ii) a passive input (fd) + active output (ie a function and a pipe)
  *)
  let go (mode : zcat_mode) (input : input_type) fd f =
    let open Safe_resources in
    Unixfd.with_pipe ~loc:__LOC__ () @@ fun zcat_out zcat_in ->
    let args =
      if mode = Compress then [] else ["--decompress"] @ ["--stdout"; "--force"]
    in
    let stdin, stdout, close_now, close_later =
      match input with
      | Active ->
          ( Some Unixfd.(!zcat_out)
          , (* input comes from the pipe+fn *)
            Some fd
          , (* supplied fd is written to *)
            zcat_out
          , (* we close this now *)
            zcat_in )
          (* close this before waitpid *)
      | Passive ->
          ( Some fd
          , (* supplied fd is read from *)
            Some Unixfd.(!zcat_in)
          , (* output goes into the pipe+fn *)
            zcat_in
          , (* we close this now *)
            zcat_out )
    in
    (* close this before waitpid *)
    let executable, args = lower_priority Algorithm.executable args in
    let pid =
      Forkhelpers.safe_close_and_exec stdin stdout None [] executable args
    in
    Unixfd.safe_close close_now ;
    finally
      (fun () -> f Unixfd.(!close_later))
      (fun () ->
        let failwith_error s =
          let string_of_mode = function
            | Compress ->
                "compress"
            | Decompress ->
                "decompress"
          in
          let msg =
            Printf.sprintf "%s failed to %s: %s"
              (Filename.basename executable)
              (string_of_mode mode) s
          in
          error "%s" msg ; failwith msg
        in
        Unixfd.safe_close close_later ;
        let open Xapi_stdext_unix in
        match snd (Forkhelpers.waitpid pid) with
        | Unix.WEXITED 0 ->
            ()
        | Unix.WEXITED i ->
            failwith_error (Printf.sprintf "exit code %d" i)
        | Unix.WSIGNALED i ->
            failwith_error
              (Printf.sprintf "killed by signal: %s"
                 (Unixext.string_of_signal i))
        | Unix.WSTOPPED i ->
            failwith_error
              (Printf.sprintf "stopped by signal: %s"
                 (Unixext.string_of_signal i)))

  let compress fd f = go Compress Active fd f

  let decompress fd f = go Decompress Active fd f

  let decompress_passive fd f = go Decompress Passive fd f
end
