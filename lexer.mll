{
  open Parser;;        (* le type "token" est défini dans parser.mli *)
(* ce n'est pas à vous d'écrire ce fichier, il est engendré automatiquement *)
exception Eof;;
}

rule token = parse    (* la "fonction" aussi s'appelle token .. *)
  | [' ' '\t']     { token lexbuf }    (* on saute les blancs et les tabulations *)
 	     	   	           (* token: appel récursif *)
                                   (* lexbuf: argument implicite
                                      associé au tampon où sont
                                      lus les caractères *)
  | '\n'            { EOL }
  | '+'             { PLUS }
  | '*'             { TIMES }
  | '-'             { MINUS }
  | '='             { EQUAL }
  | '('             { LPAREN }
  | ')'             { RPAREN }
  | "->"            { ARROW }
  | "let"           { LET }
  | "in"            { IN }
  | "begin"         { BEGIN }
  | "end"           { END }
  | "rec"           { REC }
  | "if"            { IF }
  | "then"          { THEN }
  | "else"          { ELSE }
  | "fun"           { FUN }
  | ";;"            { ENDEXPR }
  | lower(digit|lower|upper|'_')* as s {IDENT (s)}
  | ['0'-'9']+ as s { INT (int_of_string s) }
  | eof             { raise Eof } 
