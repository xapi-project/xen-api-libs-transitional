open Resources

let remove_bt = function Ok _ as r -> r | Error e -> Error (List.map fst e)

let exn = Alcotest.of_pp Fmt.exn

let test_no_raise_0 () = Exns.run_all (List.to_seq []) |> Exns.ok_or_raise_exn

let test_no_raise_1 () =
  let f () = () in
  Exns.run_all (List.to_seq [f]) |> Exns.ok_or_raise_exn

let test_one_exn () =
  let toraise = Failure "Some error" in
  let f () = raise toraise in
  let r = Exns.run_all (List.to_seq [f]) |> remove_bt in
  Alcotest.(check (result unit (list exn)) "1 error" (Error [toraise]) r)

let test_three_exn () =
  let toraise n = Failure ("Some error" ^ string_of_int n) in
  let fraise n () = raise (toraise n) in
  let count = ref 0 in
  let fok () = incr count in
  let r =
    Exns.run_all
      (List.to_seq [fok; fraise 1; fraise 2; fok; fok; fok; fraise 3])
    |> remove_bt
  in
  Alcotest.(check int "called fok 4 times" 4 !count) ;
  Alcotest.(
    check
      (result unit (list exn))
      "3 errors"
      (Error [toraise 1; toraise 2; toraise 3])
      r)

let test_raises () =
  let called = ref 0 in
  let f () = incr called in
  let g () = failwith "TEST" in
  try
    Exns.run_all (List.to_seq [f; g]) |> Exns.ok_or_raise_exn ;
    Alcotest.fail "should've raised exception"
  with Exns.DestructorRaised l ->
    Alcotest.(check (list exn) "raised" [Failure "TEST"] (List.map fst l))

let tests =
  [ (__LOC__, `Quick, test_no_raise_0)
  ; (__LOC__, `Quick, test_no_raise_1)
  ; (__LOC__, `Quick, test_one_exn)
  ; (__LOC__, `Quick, test_three_exn)
  ; (__LOC__, `Quick, test_raises) ]
