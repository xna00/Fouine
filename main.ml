open Expr
open Parser

let _ = print_endline "fouine interpreter"
let _ = print_endline (if (let x = true in x && x) then "test" else "fail")

let g x y = x - y
let g' = fun x -> fun y -> x - y
let _ = print_int (g 4 2)
let _ = print_endline ""
let _ = print_int (g' 4 2)
let h a b () = a + b

