/-
Copyright (c) 2023 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import Mathlib.Data.MvPolynomial.Equiv
import Mathlib.Data.Polynomial.Eval

/-!
# Some lemmas relating polynomials and multivariable polynomials.
-/

namespace MvPolynomial

theorem polynomial_eval_eval₂ [CommSemiring R] [CommSemiring S]
    (f : R →+* Polynomial S) (g : σ → Polynomial S) (p : MvPolynomial σ R) :
    Polynomial.eval x (eval₂ f g p) =
      eval₂ ((Polynomial.evalRingHom x).comp f) (fun s => Polynomial.eval x (g s)) p := by
  apply induction_on p
  · simp
  · intro p q hp hq
    simp [hp, hq]
  · intro p n hp
    simp [hp]

theorem eval_polynomial_eval_finSuccEquiv
    [CommSemiring R] (f : MvPolynomial (Fin (n + 1)) R) (q : MvPolynomial (Fin n) R) :
    (eval x) (Polynomial.eval q (finSuccEquiv R n f)) = eval (Fin.cases (eval x q) x) f := by
  simp only [finSuccEquiv_apply, coe_eval₂Hom, polynomial_eval_eval₂, eval_eval₂]
  conv in RingHom.comp _ _ =>
  { refine @RingHom.ext _ _ _ _ _ (RingHom.id _) fun r => ?_
    simp }
  simp only [eval₂_id]
  congr
  funext i
  refine Fin.cases (by simp) (by simp) i
