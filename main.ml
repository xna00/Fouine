open Parser
open Expr
open Errors
open Env
open Interpret
open Compil
open Binop

let _ = print_endline "fouine interpreter"
let _ = print_endline (if (let x = true in x && x) then "test" else "fail")
(*
let g x y = x - y
let g' = fun x -> fun y -> x - y
let _ = print_int (g 4 2)
let _ = print_endline ""
let _ = print_int (g' 4 2)
let h a b () = a + b
               *)



(* on enchaîne les tuyaux: lexbuf est passé à Lexer.token,
   et le résultat est donné à Parser.main *)
(*
let parse () = Parser.main Lexer.token lexbuf
let r = parse ()
let _ = print_endline @@ beautyfullprint r
let res, _ = interpret r (fun x y -> x, y) (fun x y -> x, y)
let _ = print_endline @@ beautyfullprint res
*)

(*
let ld = Lexing.dummy_pos
let st = Stack.create
let e2 = In(Const 1, Const 2, Lexing.dummy_pos)
let e3 = BinOp(addOp,Const 1, BinOp(multOp, Const 4, Const 5, ld), Lexing.dummy_pos)
let e4 = BinOp(multOp, Printin(Const 10, ld), Const 100, ld)
let l2 = compile e3 
let code1 = [C 10; C 15; BOP addOp; LET "x"; ACCESS "x"; C 3; BOP multOp; ENDLET]
let _ = print_endline @@ print_code l2
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") [C 10] (st ())
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") l2 (st ())
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") (compile e4) (st ())
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") code1 (st ())

let c = [ACCESS("x"); C 1; BOP addOp; ACCESS("x"); APPLY] 
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") [CLOSURE("x", c);  C 2; APPLY] (st ())

let c = [ACCESS("1"); C 1; APPLY] 
let _ = print_endline @@ exec (Stack.create ()) (Env.create, "") [CLOSURE(c);  C 2; APPLY]
*)
exception Error of exn * (int * int * string )
let parse_buf_exn lexbuf =
    try
      Parser.main Lexer.token lexbuf
    with exn ->
      begin
        let tok = Lexing.lexeme lexbuf in
        raise (send_parsing_error (Lexing.lexeme_start_p lexbuf) tok)
      end

type test = {pos_bol : int; pos_fname : string; pos_lnum : int; pos_cnum : int}



let rec readExpr lexbuf env =
  let r = 
    try
      parse_buf_exn lexbuf
    with ParsingError x ->
      let _ = print_endline x in Unit
  in match r with
  | Open (file, _) -> 
    let file_path = String.sub file 5 (String.length file - 5) 
    in let env' = interpretFromStream (Lexing.from_channel (open_in file_path)) file_path env in Unit, env'
  | Eol -> Eol, env
  | _ ->  let _ = print_endline @@ beautyfullprint r
    in let env'  = begin
        try
          let res, env' = interpret r env (fun x y -> x, y) (fun x y -> x, y)
          in  let _ = print_endline @@ beautyfullprint res
          in env'
        with InterpretationError x -> 
          let _ = print_endline x in env
      end in r, env'   

and repl lexbuf env = 
  let _ = print_string ">> "; flush stdout
  (*) in let parse () = Parser.main Lexer.token lexbuf
    in let r = parse ()
  *)
  in let expr, env' = readExpr lexbuf env
  in if expr = Eol then env' else repl lexbuf env'


and interpretFromStream lexbuf name env =
  let pos = lexbuf.Lexing.lex_curr_p in
  let pos = {pos_bol = pos.Lexing.pos_cnum; 
             pos_fname = pos.Lexing.pos_fname; 
             pos_lnum = pos.Lexing.pos_lnum;
             pos_cnum = pos.Lexing.pos_cnum;}


  in begin
    lexbuf.lex_curr_p <- {lexbuf.lex_curr_p with
                          pos_bol = 0;
                          pos_fname = name;
                          pos_lnum = 0;
                          pos_cnum = 0;
                        };
    let env' = repl lexbuf env in
    lexbuf.lex_curr_p <- {lexbuf.lex_curr_p with
                         pos_bol = pos.pos_bol;
                         pos_fname = pos.pos_fname;
                         pos_lnum = pos.pos_lnum;
                         pos_cnum = pos.pos_cnum;
                        };
      env'
    end


(* let _ = repl (Env.create) *)

let lexbuf = Lexing.from_channel stdin (*(open_in "test.fo")*)
let _ = interpretFromStream lexbuf "test" (Env.create)

(*
let test () = begin
    let a = 4 in let  b = 8 in 4;
    let a = 4 in 8;
    a * 10 + b
end
let _ = print_int (test ())
*)
