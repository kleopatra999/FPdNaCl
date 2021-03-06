(* FPdNaCl
 * 
 * Copyright (C) 2011 Alexandre Pilkiewicz (@polytechnique.org)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details. *)

Require Export Case_Tactics.
Require Export Omega.
Require Export NArith.
Require Import RelationClasses.
Require Import Program.
Require Export List.
Require Export DoOption.
Open Scope bool_scope.


Ltac omega' := zify; omega.

Ltac inv H := inversion H; clear H; try subst.
Definition eq_dec (X: Type):= forall (x1 x2:X), {x1 = x2}+{x1 <> x2}.

Notation "[ ]" := (nil).
Notation "[ x , .. , z ]" := (cons x ( .. (cons z []) .. )).

Fixpoint list_take {A} n (l: list A) : list A:=
  match n, l with
    | O, _
    | _, [] => []
    | S n', h::t => h :: (list_take n' t)
  end.

Fixpoint list_drop {A} n (l: list A) : list A:=
  match n, l with
    | O, _ => l
    | _, [] => []
    | S n', h::t => (list_drop n' t)
  end.

Create HintDb clean.
Generalizable Variable A B.

Implicit Arguments fst [[A] [B]].
Implicit Arguments snd [[A] [B]].

Set Implicit Arguments.

Ltac inv_opt :=
 repeat
   (match goal with
    | H : match ?X with
            | Some _ => Some _
            | None => None
          end = Some _ |- _ =>
    case_eq X; intros;
      match goal with
        | HEQ : X = _ |- _ =>
          rewrite HEQ in H; simpl in *; inv H; auto
      end
  end);
 repeat
   (match goal with
    | H : match ?X with
            | Some _ => Some _
            | None => None
          end = None |- _ =>
    case_eq X; intros;
      match goal with
        | HEQ : X = _ |- _ =>
          rewrite HEQ in H; simpl in *; inv H; auto
      end
  end);
 repeat
   (match goal with
    | H : match ?X with
            | Some _ => _
            | None => False
          end |- _ =>
    case_eq X; intros;
    match goal with
      | H' : X = _ |- _ =>
        rewrite H' in H; auto
    end
  end).

Ltac inv_res :=
 repeat
   (match goal with
    | H : match ?X with
            | OK _ => OK _
            | Err _ => Err _
          end = OK _ |- _ =>
    case_eq X; intros;
      match goal with
        | HEQ : X = _ |- _ =>
          rewrite HEQ in H; simpl in *; inv H; auto
      end
  end);
 repeat
   (match goal with
    | H : match ?X with
            | OK _ => OK _
            | Err _ => Err _
          end = Err _ |- _ =>
    case_eq X; intros;
      match goal with
        | HEQ : X = _ |- _ =>
          rewrite HEQ in H; simpl in *; inv H; auto
      end
  end);
 repeat
   (match goal with
    | H : match ?X with
            | OK _ => _
            | Err _ => False
          end |- _ =>
    case_eq X; intros;
    match goal with
      | H' : X = _ |- _ =>
        rewrite H' in H; auto
    end
  end).


(* a type to do rewriting only in the environement *)

Inductive imp_rew (P1 P2: Prop) : Prop:=
  | IR : (P1 -> P2) -> imp_rew P1 P2.
Hint Constructors imp_rew.

Notation " A '-r>' B" := (imp_rew A B) (at level 90).

Lemma ir_refl: forall A, A -r> A.
Proof.
  auto.
Qed.

Lemma ir_trans: forall A B C, (A -r> B) -> (B -r> C) -> (A -r> C).
Proof.
  intuition.
Qed.

Add Relation Prop imp_rew
  reflexivity proved by ir_refl
  transitivity proved by ir_trans
  as imp_rewSetoid.

Instance imp_rew_sub: subrelation imp_rew impl.
Proof.
  compute.
  intuition.
Qed.


Inductive is_some {A:Type}: (option A)-> Prop :=
| IsSome: forall a:A, is_some (Some a).

Hint Constructors is_some.


(* is_some on a Some is useless *)
Lemma is_some_Some {A:Type} (a:A):
  is_some (Some a) -r> True.
Proof. intuition. Qed.

(* is_some on a None is false *)
Lemma is_some_None {A:Type}:
  is_some (@None A) -r> False.
Proof. intuition. inversion H. Qed.

Hint Rewrite @is_some_Some @is_some_None: clean.

Ltac solve_is_some :=
  intros;
  match goal with
    | H : is_some None |- _ => inv H
    | |- is_some (Some ?x) => apply IsSome
    | H : ?X = Some ?Y |- is_some ?X =>
      rewrite H; apply IsSome
    | H : Some ?Y = ?X |- is_some ?X =>
      rewrite <- H; apply IsSome
  end; fail.


Inductive is_ok {RES :Type}: res RES -> Prop :=
  IsOK: forall r: RES, is_ok (OK r).
Hint Constructors is_ok.

Lemma is_ok_OK {RES:Type} (a:RES):
  is_ok (@OK RES  a) -r> True.
Proof. 
  constructor. auto.
Qed.

Lemma is_ok_Err {RES :Type} s:
  @is_ok RES (@Err RES s) -r> False.
Proof.
  constructor. intro H. inversion H.
Qed.

Hint Rewrite @is_ok_OK @is_ok_Err: clean.

Ltac solve_is_ok :=
  intros;
  match goal with
    | H : is_ok (Err _) |- _ => inv H
    | |- is_ok (OK ?x) => apply IsOK
    | H : ?X = OK ?Y |- is_ok ?X =>
      rewrite H; apply IsOK
    | H : OK ?Y = ?X |- is_ok ?X =>
      rewrite <- H; apply IsSome
  end; fail.



Ltac solve_contradiction :=
  intros;
  match goal with
    | H : False |- _ => inversion H
    | H : ?X <> ?X |- _ => elimtype False; apply H; reflexivity
    | H : S ?X = O |- _ => inversion H
    | H : O = S ?X |- _ => inversion H
    | H : Some ?X = None |- _ => inversion H
    | H : None = Some ?X |- _ => inversion H
    | H : OK _ = Err _ |- _ => inversion H
    | H : Err _ = OK _ |- _ => inversion H
    | H : true = false |- _ => inversion H
    | H : false = true |- _ => inversion H
    | H : in_left = in_right |- _ => inversion H
    | H : in_right = in_left |- _ => inversion H
(*    | H : proj_sumbool in_left = false |- _ => inversion H
    | H : proj_sumbool in_right = true |- _ => inversion H
    | H : false = proj_sumbool in_left |- _ => inversion H
    | H : true = proj_sumbool in_right |- _ => inversion H*)
  end; fail.



Hint Extern 5 => solve_is_some.
Hint Extern 5 => solve_is_ok.
Hint Extern 5 => solve_contradiction.


Definition ident := positive.

Hint Unfold ident.
Hint Unfold ident: aliases.

Tactic Notation "unalias" := autounfold with aliases.
Tactic Notation "unalias" "in" constr(H) := autounfold with aliases in H.
Tactic Notation "unalias" "in" "*" := autounfold with aliases in *.
Tactic Notation "unalias" "*" := autounfold with aliases in *.

Ltac unfold' X := rewrite X.


Notation "'nosimpl' t" := (let '(tt) := tt in t) (at level 10).


Ltac option_on_right :=
  repeat
    match goal with
      | H : _ |- _ =>
        match type of H with
          | _ = None => fail 1
          | _ = Some _ => fail 1
          | Some _ = _ => symmetry in H
          | None = _ => symmetry in H
        end
    end.

Ltac res_on_right :=
  repeat
    match goal with
      | H : _ |- _ =>
        match type of H with
          | _ = Err _ => fail 1
          | _ = OK _ => fail 1
          | OK _ = _ => symmetry in H
          | Err _ = _ => symmetry in H
        end
    end.

Lemma refl_True {A:Type} (a:A): a = a -r> True.
Proof.
  intuition.
Qed.
Lemma diff_False {A:Type} (a:A): a <> a -r> False.
Proof.
  intuition.
Qed.

Hint Rewrite @refl_True @diff_False: clean.


Create HintDb opt_inv.
Lemma type_of_JMeq_eq: forall A B (a:A) (b:B), a ~=b -> A = B.
Proof.
  intros. inv H. reflexivity.
Qed.


Definition TAG_INV {P} (p:P) := p.
Notation "'tag_to_inv' ( X )" := (X -r> TAG_INV ( X )%type) (at level 0, only parsing).
Definition TAG_INV_MULTI {P} (p:P) := p.
Notation "'tag_to_inv_multi' ( X )" := (X -r> TAG_INV_MULTI ( X )%type) (at level 0, only parsing).

Ltac option_inv_aux H :=
  progress (autorewrite with opt_inv in H);
  match type of H with
    | TAG_INV _ => inv H; [idtac]
    | TAG_INV_MULTI _ => inv H
  end.

Tactic Notation "option_inv" hyp(H) :=
  try (option_inv_aux H).
Tactic Notation "option_inv" "*" :=
  repeat
  match goal with
    | H : _ |- _ => option_inv_aux H
  end.


Tactic Notation "clean" "in" hyp(H) :=
  repeat (progress (autorewrite with clean in H; option_inv H)).
Tactic Notation "clean" "in" "*" :=
  repeat (progress (autorewrite with clean in *; option_inv *)).

Tactic Notation "clean" "in" "*" "|-" :=
  repeat (progress (autorewrite with clean in * |-; option_inv *)).

Tactic Notation "clean" "in" "|-" "*" :=
  autorewrite with clean in |- *.

Ltac revert_all_of_type A :=
  repeat match goal with
    | H : A |- _ => revert dependent H
  end.

Inductive _MARK_:Prop := MARK.

Ltac pose_mark :=
  generalize MARK.

Ltac intros_until_mark :=
  repeat
  (match goal with
     | H : _MARK_ |- _ => fail 1
     | _ => idtac
   end; intro);
  (match goal with
     | H : _MARK_ |- _ => clear H
     | _ => idtac
   end)
  .


Ltac normalize_env_aux :=
  repeat
    match goal with
      | H : True |- _ => clear H
      | H : (_, _) = (_, _) |- _ => inversion H; clear H
      | H : @JMeq ?A ?a ?A ?b |- _ => apply JMeq_eq in H
      | H : @JMeq ?A ?a ?B ?b |- _ =>
        pose proof (type_of_JMeq_eq H);
        pose_mark;
        revert_all_of_type A;
        subst; intros_until_mark; apply JMeq_eq in H
    end.

Ltac normalize_env :=
  clean in * |-; normalize_env_aux.

Tactic Notation "clean" :=
  repeat (progress (
  clean in *;
  normalize_env_aux;
  option_on_right;
  res_on_right;
  try solve_contradiction;
  subst; auto)).

Tactic Notation "clean" "no" "auto" :=
  repeat (progress (
  clean in *;
  normalize_env_aux;
  option_on_right;
  res_on_right;
  try solve_contradiction;
  subst)).


Ltac prog_match_option :=
  match goal with
    | H : context[match ?X with |Some x => _ | None =>  _ end] |- _ =>
      destruct X as [x|] _eqn
    | |- context[match ?X with |Some x => _ | None =>  _ end] =>
      destruct X as [x|] _eqn
  end.

Ltac prog_match_res :=
  match goal with
    | H : context[match ?X with |OK x => _ | Err y =>  _ end] |- _ =>
      destruct X as [x|y] _eqn
    | |- context[match ?X with |OK x => _ | Err y =>  _ end] =>
      destruct X as [x|y] _eqn
  end.

Tactic Notation "dest_if_aux" constr(TERM) "as" simple_intropattern(pat):=
  match TERM with
    | context[if ?EXP then _ else _] =>
      destruct EXP as pat _eqn
  end.

Tactic Notation "dest_if_aux" constr(TERM) :=
  dest_if_aux TERM as [].

Tactic Notation "dest_if" "in" hyp(H) "as" simple_intropattern(pat) :=
  let TERM := type of H in
   dest_if_aux TERM as pat.

Tactic Notation "dest_if" "in" hyp(H) :=
  dest_if in H as [].

Tactic Notation "dest_if" "as" simple_intropattern(pat) :=
  match goal with
    | H : ?TERM |- _ => dest_if_aux TERM as pat
  end.
Tactic Notation "dest_if" := dest_if as [].

Tactic Notation "dest_if_goal" "as" simple_intropattern(pat) :=
  match goal with
    | |- ?TERM => dest_if_aux TERM as pat
  end.

Tactic Notation "dest_if_goal" := dest_if_goal as [].


Tactic Notation "inv_clean" hyp(H) := inv H; clean.
Tactic Notation "inv'" hyp(H) := cases H (inv H).
Tactic Notation "inv_clean'" hyp(H) := inv' H; clean.

Lemma remove_some: forall A (x y: A), Some x = Some y -r> x = y.
Proof.
  split; congruence. 
Qed.

Lemma remove_ok: forall A (x y: A), OK x = OK y -r> x = y.
Proof.
  split; congruence. 
Qed.

Hint Rewrite remove_some remove_ok: clean.

Local Open Scope N_scope.

Definition safe_minus (n m : N): option N :=
  match n with
    | 0 =>
      match m with
        | 0 => Some 0
        | _ => None
      end
    | Npos n' =>
      match m with
        | 0%N => Some n
        | Npos m' =>
          match Pminus_mask n' m' with
            | IsNul => Some 0%N
            | IsPos p => Some (Npos p)
            | IsNeg => None
          end
      end
  end.


Lemma safe_minus_inf_is_some: forall n m,
  m <= n -> is_some (safe_minus n m).
Proof.
  intros.
  assert ( m = n \/ n > m) as SPLIT. omega'. clear H.
  destruct SPLIT as [H | H].
  Case "m = n".
    subst. unfold safe_minus.
    destruct n; auto.
    rewrite Pminus_mask_diag; auto.

  Case "m <> n".
    unfold Nlt in H.
    unfold safe_minus.
    destruct n; destruct m; auto; simpl in H.
      inv H.

    apply Pminus_mask_Gt in H.
    decompose [and ex] H.
    rewrite H1. auto.
Qed.

Lemma safe_minus_sup_is_None: forall n m,
  n < m -> safe_minus n m = None.
Proof.
  intros.
  unfold Nlt in H.
  unfold safe_minus.
  destruct n; destruct m; auto; simpl in H; try solve [inv H].
  rewrite Pminus_mask_Lt; auto.
Qed.


Lemma safe_minus_correct: forall n m p, safe_minus n m = Some p ->
  n  = (m + p).
Proof.

  intros.

  assert ((n - m) = p).
  unfold Nminus, safe_minus in *.
  destruct n; destruct m; clean.
  destruct (Pminus_mask p0 p1); clean.

  assert (~(n < m)) by (intro INF; apply safe_minus_sup_is_None in INF; congruence).
  assert (m <= n) by omega'.
  omega'.
Qed.


