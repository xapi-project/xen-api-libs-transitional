let () =
  Printexc.record_backtrace true ;
  Sys.enable_runtime_warnings true ;
  Logs.set_reporter (Logs_fmt.reporter ()) ;
  Logs.set_level ~all:true (Some Logs.Debug) ;
  Alcotest.run "Resources"
    [ ("Safe_dropable", Safe_dropable_test.tests)
    ; ("Unixfd finaliser", Unixfd_test.tests)
    ; ("Exns", Exns_test.tests)
    ; ("Scope", Scope_test.tests)
    ; ("Scoped dropable", Scoped_dropable_test.tests) ]
