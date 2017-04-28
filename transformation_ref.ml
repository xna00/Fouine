open Env
open Prettyprint
open Expr

let p = Lexing.dummy_pos
let memory_name = Ident("tr_memory", p)


(*
let allocate = Fun(Ident("tr_v", p), Fun(Ident("tr_s1", p), Tuple([Ref(Ident("tr_v", p), p); Ident("tr_s1", p)], p), p), p)
let read = Fun(Ident("tr_v", p), Fun(Ident("tr_s1", p), Bang(Ident("tr_v", p), p), p), p)
let modify =Fun(Ident("tr_s2", p), Fun(Tuple([Ident("tr_l1", p); Ident("tr_v2", p)], p), 
                                     Seq(BinOp(refSet, Ident("tr_l1", p), Ident("tr_v2", p), p), Ident("tr_s2", p), p), p),p)
*)
let allocate = Ident("buildins_allocate", p)
let read = Ident("buildins_read", p)
let modify = Ident("buildins_modify", p)
let create = Ident("buildins_create", p)


(* refs will be representend by a const equivalent to a pointer. We use inference to make sure that the typing is correct *)
let rec transform_ref code =
  let rec aux code = 
    match code with
    | Const _ -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | Bool _ -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | Unit -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | Underscore -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | TypeDecl _ -> code
    | Constructor_noarg _ -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | Constructor (name, expr, error) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_v1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             Tuple([Constructor(name, Ident("tr_v1", p), error); Ident("tr_s1", p)], p), p)
            , p)
    | Tuple (l, p) -> 
        let rec aux_tuple l e  acc i = begin match l with
          | [] -> Tuple([Tuple(List.rev acc, p); e], p)
    | x::t -> In(Let(Tuple([Ident("tr_v"^string_of_int i, p); Ident("tr_s"^string_of_int i, p)], p), Call(aux x, e, p), p),
                    aux_tuple t (Ident("tr_s"^string_of_int i, p)) (Ident("tr_v"^string_of_int i, p)::acc) (i+1), p)
        end in Fun(memory_name, aux_tuple l memory_name [] 0, p)
      
    | MatchWith(expr, pattern_actions, err) ->
      Fun(memory_name,
          In(Let(Tuple([Ident("tr_v1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             MatchWith(Ident("tr_v1", p),
                      List.map (fun (a, b) -> a, Call(aux b, Ident("tr_s1", p), p)) pattern_actions
                      , p)
         , p),p)
      
    | Ident _ -> Fun(memory_name, Tuple([code; memory_name], p), p)
    | RefValue _ -> 
      
      Fun(memory_name, Tuple([code; memory_name], p), p)
    | Array _ -> Fun(memory_name, Tuple([code; memory_name], p), p)

    | BinOp(x, a, b, er) when x#symbol = ":=" -> 
      Fun (memory_name,
           In(Let(Tuple([Ident("tr_l1", p); Ident("tr_s1", p)], p),
                  Call(aux a, memory_name, p), p),
             In(Let(Tuple([Ident("tr_v2", p); Ident("tr_s2", p)], p),
                    Call(aux b, Ident("tr_s1", p), p), p),
                In(Let(Ident("tr_s3", p), 
                       Call(Call(modify,
                                 Ident("tr_s2", p), p),
                            Tuple([Ident("tr_l1", p); Ident("tr_v2", p)], p), p)
                      , p),
                   Tuple([Ident("tr_v2", p); Ident("tr_s3", p)], p), p),p),p),p)

    | BinOp(x, a, b, er) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_f1", p); Ident("tr_s1", p)], p), Call(aux a, memory_name, p), p),
             In( Let(Tuple([Ident("tr_f2", p); Ident("tr_s2", p)], p), Call(aux b, Ident("tr_s1", p), p), p),
                 Tuple([BinOp(x, Ident("tr_f1", p), Ident("tr_f2", p), er); Ident("tr_s2", p)], p), p), p ), p)
    | Let(a, b, er) ->
      Let(Tuple([a; Underscore], p),
         aux b, p
         
         )
  (*    Fun(memory_name, 
          In(Let (Tuple([Ident("tr_x1", p); Ident("tr_s1", p)], p), Call(aux b, memory_name, p), p),
             In(Let(a, Ident("tr_x1", p), er), Tuple([a; Ident("tr_s1", p)], p), p)
            ,p), p)

*)
    | In(Let(a, b, er), expr, _) ->
      Fun(memory_name, 
          In(Let (Tuple([Ident("tr_x1", p); Ident("tr_s1", p)], p), Call(aux b, memory_name, p), p),
             In(Let(a, Ident("tr_x1", p), er), Call(aux expr, Ident("tr_s1", p), p), p)
            ,p), p)
    | LetRec(a, Fun(arg, e, _), er) ->
    Fun(memory_name, 
        In(LetRec(a, Fun(arg, aux e, p), p),
           Tuple([a; memory_name], p)
       , p), p)
    | In(LetRec(a, Fun(arg, e, _), er), expr, _) ->
    Fun(memory_name, 
        In(LetRec(a, Fun(arg, aux e, p), p),
           Call(aux expr, memory_name, p)
             , p),p
       )


    | Ref (x, error_infos) -> 
      Fun(memory_name,
          In(Let(Tuple([Ident("tr_v", p); Ident("tr_s1", p)], p)
                , Call(aux x, memory_name, p),p), 
             In(Let(Tuple([Ident("tr_l", p); Ident("tr_s2", p)], p),
                    Call(Call(allocate, Ident("tr_v", p), p), Ident("tr_s1", p), p)
                   , p),
                  Tuple([Ident("tr_l",p); Ident("tr_s2", p)], p), p)
            , p)
         , p)
    | Bang(x, er) ->
      Fun(memory_name,
          In(Let(Tuple([Ident("tr_l", p); Ident("tr_s1", p)], p),
                 Call(aux x, memory_name, p), p),
             In(Let(Ident("tr_v", p), 
                    Call(Call(read, Ident("tr_l",p ),p), Ident("tr_s1", p), p), p)
               , Tuple([Ident("tr_v", p); Ident("tr_s1", p)], p), p), p), p)

    | MainSeq(a, b, er) | Seq(a, b, er) ->
      Fun(memory_name, Call(aux (
        In(Let(Underscore, a, p), b, er)
        ), memory_name, p), p)

(* we put the fun s -> at the end of the function calls: exemple
   fun x -> fun y -> expr is transform in fun x -> fun y -> fun s -> [|expr|] s *)
    | Fun(arg, expr, er) ->
      Fun(memory_name, Tuple([Fun(arg, aux expr, p); memory_name], p), p)
    | Call(Constructor_noarg(name, error), b, er) ->
      aux (Constructor(name, b, error))
    | Call(a, b, er) -> 
      (* f x <=> fun s -> let x1, s1 = [|x|] s in let x2, s2 = f s1 x1)*)

      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_f1", p); Ident("tr_s1", p)], p), Call(aux a, memory_name, p), p),
             In( Let(Tuple([Ident("tr_v2", p); Ident("tr_s2", p)], p), Call(aux b, Ident("tr_s1", p), p), p),
                Call(Call(Ident("tr_f1", p), Ident("tr_v2", p), p), Ident("tr_s2", p), p),p ), p ), p)

    | IfThenElse (cond, a, b, er) ->
      Fun(memory_name,
          In(Let(Tuple([Ident("tr_c1", p); Ident("tr_s1", p)], p),
                 Call(aux cond, memory_name, p), p),
             IfThenElse(Ident("tr_c1", p),
                        Call(aux a, Ident("tr_s1", p), p),
                       Call(aux b, Ident("tr_s1", p), p), p), p
            ), p
         )
    | Raise(expr, er) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_c1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             Tuple([Raise(Ident("tr_c1", p), er); Ident("tr_s1", p)], p)
               ,p),p)
    | Not (expr, er) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_c1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             Tuple([Not(Ident("tr_c1", p), er); Ident("tr_s1", p)], p)
               ,p),p)
    | Printin (expr, er) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_c1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             Tuple([Printin(Ident("tr_c1", p), er); Ident("tr_s1", p)], p)
               ,p),p)
    | ArrayMake (expr, er) ->
      Fun(memory_name, 
          In(Let(Tuple([Ident("tr_c1", p); Ident("tr_s1", p)], p),
                 Call(aux expr, memory_name, p), p),
             Tuple([ArrayMake(Ident("tr_c1", p), er); Ident("tr_s1", p)], p)
               ,p),p)

    | ArrayItem (ar, index, er) ->
      Fun(memory_name,
          In(
            Let(Tuple([Ident("tr_ar", p); Ident("tr_s1", p)],p), Call(aux ar, memory_name, p),p),
            In(
              Let(Tuple([Ident("tr_in", p); Ident("tr_s2", p)], p), Call(aux index, Ident("tr_s1", p), p), p),
              Tuple([ArrayItem(Ident("tr_ar", p), Ident("tr_in", p), p); Ident("tr_s2",p)], p)
               ,p)
               ,p),p)
            
    | ArraySet (ar, index, what, er) ->
      Fun(memory_name,
          In(
            Let(Tuple([Ident("tr_ar", p); Ident("tr_s1", p)],p), Call(aux ar, memory_name, p),p),
            In(
              Let(Tuple([Ident("tr_in", p); Ident("tr_s2", p)], p), Call(aux index, Ident("tr_s1", p), p), p),
              In( 
                Let(Tuple([Ident("tr_wh", p); Ident("tr_s3", p)], p), Call(aux what, Ident("tr_s2", p), p), p),
              Tuple([ArraySet(Ident("tr_ar", p), Ident("tr_in", p), Ident("tr_wh",p), p); Ident("tr_s3",p)], p)
               ,p)
               ,p),p),p)

    | TryWith(tr, pattern, expr, er) -> failwith "trywith not implemented"

    | LetRec _ | In _ -> failwith "syntax"
    | _ -> failwith "it shouldn't had occured"

  in let code' = aux code
  in match code' with
  | TypeDecl _ -> code'
  | Let (a, b, e) -> begin match code with
      | Let(temp, _, _) ->  Let(temp, In(Let(a, Call(b, create, p), e), temp, p), p)
    | _ -> failwith "an other thing that wasn't supposed to happend"
        end
  | _ -> In(Let(Tuple([Ident("tr_result", p); Ident("tr_env", p)], p), Call(code', create
                                                                          , p), p), Ident("tr_result", p), p)

