module type S = sig
  type t

  val scope : t
end

module Dummy = struct
  type t = unit

  let scope = ()
end

let create () = (module Dummy : S)
