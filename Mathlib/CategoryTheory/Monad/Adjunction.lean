/-
Copyright (c) 2019 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Bhavik Mehta

! This file was ported from Lean 3 source module category_theory.monad.adjunction
! leanprover-community/mathlib commit ea3009f6c1a37dc031f741382dbb3ed93c965620
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.CategoryTheory.Adjunction.Reflective
import Mathlib.CategoryTheory.Monad.Algebra

/-!
# Adjunctions and monads

We develop the basic relationship between adjunctions and monads.

Given an adjunction `h : L ⊣ R`, we have `h.toMonad : Monad C` and `h.toComonad : Comonad D`.
We then have
`Monad.comparison (h : L ⊣ R) : D ⥤ h.toMonad.algebra`
sending `Y : D` to the Eilenberg-Moore algebra for `L ⋙ R` with underlying object `R.obj X`,
and dually `Comonad.comparison`.

We say `R : D ⥤ C` is `MonadicRightAdjoint`, if it is a right adjoint and its `Monad.comparison`
is an equivalence of categories. (Similarly for `ComonadicLeftAdjoint`.)

Finally we prove that reflective functors are `MonadicRightAdjoint`.
-/


namespace CategoryTheory

open Category

universe v₁ v₂ u₁ u₂

-- morphism levels before object levels. See note [category_theory universes].
variable {C : Type u₁} [Category.{v₁} C] {D : Type u₂} [Category.{v₂} D]

variable {L : C ⥤ D} {R : D ⥤ C}

namespace Adjunction

/-- For a pair of functors `L : C ⥤ D`, `R : D ⥤ C`, an adjunction `h : L ⊣ R` induces a monad on
the category `C`.
-/
-- Porting note: Specifying simps projections manually to match mathlib3 behavior.
@[simps! coe η μ]
def toMonad (h : L ⊣ R) : Monad C where
  toFunctor := L ⋙ R
  η' := h.unit
  μ' := whiskerRight (whiskerLeft L h.counit) R
  assoc' X := by
    dsimp
    rw [← R.map_comp]
    simp
  right_unit' X := by
    dsimp
    rw [← R.map_comp]
    simp
#align category_theory.adjunction.to_monad CategoryTheory.Adjunction.toMonad

/-- For a pair of functors `L : C ⥤ D`, `R : D ⥤ C`, an adjunction `h : L ⊣ R` induces a comonad on
the category `D`.
-/
-- Porting note: Specifying simps projections manually to match mathlib3 behavior.
@[simps coe ε δ]
def toComonad (h : L ⊣ R) : Comonad D where
  toFunctor := R ⋙ L
  ε' := h.counit
  δ' := whiskerRight (whiskerLeft R h.unit) L
  coassoc' X := by
    dsimp
    rw [← L.map_comp]
    simp
  right_counit' X := by
    dsimp
    rw [← L.map_comp]
    simp
#align category_theory.adjunction.to_comonad CategoryTheory.Adjunction.toComonad

/-- The monad induced by the Eilenberg-Moore adjunction is the original monad.  -/
@[simps!]
def adjToMonadIso (T : Monad C) : T.adj.toMonad ≅ T :=
  MonadIso.mk (NatIso.ofComponents (fun X => Iso.refl _) (by aesop_cat))
    (fun X => by
      dsimp
      simp)
    fun X => by
    dsimp
    simp
#align category_theory.adjunction.adj_to_monad_iso CategoryTheory.Adjunction.adjToMonadIso

/-- The comonad induced by the Eilenberg-Moore adjunction is the original comonad. -/
@[simps!]
def adjToComonadIso (G : Comonad C) : G.adj.toComonad ≅ G :=
  ComonadIso.mk (NatIso.ofComponents (fun X => Iso.refl _) (by aesop_cat))
    (fun X => by
      dsimp
      simp)
    fun X => by
    dsimp
    simp
#align category_theory.adjunction.adj_to_comonad_iso CategoryTheory.Adjunction.adjToComonadIso

end Adjunction

/-- Gven any adjunction `L ⊣ R`, there is a comparison functor `CategoryTheory.Monad.comparison R`
sending objects `Y : D` to Eilenberg-Moore algebras for `L ⋙ R` with underlying object `R.obj X`.

We later show that this is full when `R` is full, faithful when `R` is faithful,
and essentially surjective when `R` is reflective.
-/
@[simps]
def Monad.comparison (h : L ⊣ R) : D ⥤ h.toMonad.Algebra where
  obj X :=
    { A := R.obj X
      a := R.map (h.counit.app X)
      assoc := by
        dsimp
        rw [← R.map_comp, ← Adjunction.counit_naturality, R.map_comp] }
  map f :=
    { f := R.map f
      h := by
        dsimp
        rw [← R.map_comp, Adjunction.counit_naturality, R.map_comp] }
#align category_theory.monad.comparison CategoryTheory.Monad.comparison

/-- The underlying object of `(Monad.comparison R).obj X` is just `R.obj X`.
-/
@[simps]
def Monad.comparisonForget (h : L ⊣ R) : Monad.comparison h ⋙ h.toMonad.forget ≅ R where
  hom := { app := fun X => 𝟙 _ }
  inv := { app := fun X => 𝟙 _ }
#align category_theory.monad.comparison_forget CategoryTheory.Monad.comparisonForget

theorem Monad.left_comparison (h : L ⊣ R) : L ⋙ Monad.comparison h = h.toMonad.free :=
  rfl
#align category_theory.monad.left_comparison CategoryTheory.Monad.left_comparison

instance [Faithful R] (h : L ⊣ R) : Faithful (Monad.comparison h)
    where map_injective {_ _} _ _ w := R.map_injective (congr_arg Monad.Algebra.Hom.f w : _)

instance (T : Monad C) : Full (Monad.comparison T.adj)
    where preimage {_ _} f := ⟨f.f, by simpa using f.h⟩

instance (T : Monad C) : EssSurj (Monad.comparison T.adj)
    where mem_essImage X :=
    ⟨{  A := X.A
        a := X.a
        unit := by simpa using X.unit
        assoc := by simpa using X.assoc }, ⟨Monad.Algebra.isoMk (Iso.refl _) (by simp)⟩⟩

/--
Gven any adjunction `L ⊣ R`, there is a comparison functor `CategoryTheory.Comonad.comparison L`
sending objects `X : C` to Eilenberg-Moore coalgebras for `L ⋙ R` with underlying object
`L.obj X`.
-/
@[simps]
def Comonad.comparison (h : L ⊣ R) : C ⥤ h.toComonad.Coalgebra where
  obj X :=
    { A := L.obj X
      a := L.map (h.unit.app X)
      coassoc := by
        dsimp
        rw [← L.map_comp, ← Adjunction.unit_naturality, L.map_comp] }
  map f :=
    { f := L.map f
      h := by
        dsimp
        rw [← L.map_comp]
        simp }
#align category_theory.comonad.comparison CategoryTheory.Comonad.comparison

/-- The underlying object of `(Comonad.comparison L).obj X` is just `L.obj X`.
-/
@[simps]
def Comonad.comparisonForget {L : C ⥤ D} {R : D ⥤ C} (h : L ⊣ R) :
    Comonad.comparison h ⋙ h.toComonad.forget ≅ L where
  hom := { app := fun X => 𝟙 _ }
  inv := { app := fun X => 𝟙 _ }
#align category_theory.comonad.comparison_forget CategoryTheory.Comonad.comparisonForget

theorem Comonad.left_comparison (h : L ⊣ R) : R ⋙ Comonad.comparison h = h.toComonad.cofree :=
  rfl
#align category_theory.comonad.left_comparison CategoryTheory.Comonad.left_comparison

instance Comonad.comparison_faithful_of_faithful [Faithful L] (h : L ⊣ R) :
    Faithful (Comonad.comparison h)
    where map_injective {_ _} _ _ w := L.map_injective (congr_arg Comonad.Coalgebra.Hom.f w : _)
#align category_theory.comonad.comparison_faithful_of_faithful CategoryTheory.Comonad.comparison_faithful_of_faithful

instance (G : Comonad C) : Full (Comonad.comparison G.adj)
    where preimage f := ⟨f.f, by simpa using f.h⟩

instance (G : Comonad C) : EssSurj (Comonad.comparison G.adj)
    where mem_essImage X :=
    ⟨{  A := X.A
        a := X.a
        counit := by simpa using X.counit
        coassoc := by simpa using X.coassoc }, ⟨Comonad.Coalgebra.isoMk (Iso.refl _) (by simp)⟩⟩

/-- A right adjoint functor `R : D ⥤ C` is *monadic* if the comparison functor `Monad.comparison R`
from `D` to the category of Eilenberg-Moore algebras for the adjunction is an equivalence.
-/
class MonadicRightAdjoint (R : D ⥤ C) extends IsRightAdjoint R where
  eqv : IsEquivalence (Monad.comparison (Adjunction.ofRightAdjoint R))
#align category_theory.monadic_right_adjoint CategoryTheory.MonadicRightAdjoint

/--
A left adjoint functor `L : C ⥤ D` is *comonadic* if the comparison functor `Comonad.comparison L`
from `C` to the category of Eilenberg-Moore algebras for the adjunction is an equivalence.
-/
class ComonadicLeftAdjoint (L : C ⥤ D) extends IsLeftAdjoint L where
  eqv : IsEquivalence (Comonad.comparison (Adjunction.ofLeftAdjoint L))
#align category_theory.comonadic_left_adjoint CategoryTheory.ComonadicLeftAdjoint

noncomputable instance (T : Monad C) : MonadicRightAdjoint T.forget :=
  ⟨(Equivalence.ofFullyFaithfullyEssSurj _ : IsEquivalence (Monad.comparison T.adj))⟩

noncomputable instance (G : Comonad C) : ComonadicLeftAdjoint G.forget :=
  ⟨(Equivalence.ofFullyFaithfullyEssSurj _ : IsEquivalence (Comonad.comparison G.adj))⟩

-- TODO: This holds more generally for idempotent adjunctions, not just reflective adjunctions.
instance μ_iso_of_reflective [Reflective R] : IsIso (Adjunction.ofRightAdjoint R).toMonad.μ := by
  dsimp
  infer_instance
#align category_theory.μ_iso_of_reflective CategoryTheory.μ_iso_of_reflective

attribute [instance] MonadicRightAdjoint.eqv

attribute [instance] ComonadicLeftAdjoint.eqv

namespace Reflective

instance [Reflective R] (X : (Adjunction.ofRightAdjoint R).toMonad.Algebra) :
    IsIso ((Adjunction.ofRightAdjoint R).unit.app X.A) :=
  ⟨⟨X.a,
      ⟨X.unit, by
        dsimp only [Functor.id_obj]
        rw [← (Adjunction.ofRightAdjoint R).unit_naturality]
        dsimp only [Functor.comp_obj, Adjunction.toMonad_coe]
        rw [unit_obj_eq_map_unit, ← Functor.map_comp, ← Functor.map_comp]
        erw [X.unit]
        simp⟩⟩⟩

instance comparison_essSurj [Reflective R] :
    EssSurj (Monad.comparison (Adjunction.ofRightAdjoint R)) := by
  refine' ⟨fun X => ⟨(leftAdjoint R).obj X.A, ⟨_⟩⟩⟩
  symm
  refine' Monad.Algebra.isoMk _ _
  · exact asIso ((Adjunction.ofRightAdjoint R).unit.app X.A)
  dsimp only [Functor.comp_map, Monad.comparison_obj_a, asIso_hom, Functor.comp_obj,
    Monad.comparison_obj_A, Adjunction.toMonad_coe]
  rw [← cancel_epi ((Adjunction.ofRightAdjoint R).unit.app X.A)]
  dsimp only [Functor.id_obj, Functor.comp_obj]
  rw [Adjunction.unit_naturality_assoc,
    Adjunction.right_triangle_components, comp_id]
  apply (X.unit_assoc _).symm
#align category_theory.reflective.comparison_ess_surj CategoryTheory.Reflective.comparison_essSurj

instance comparisonFull [Full R] [IsRightAdjoint R] :
    Full (Monad.comparison (Adjunction.ofRightAdjoint R)) where preimage f := R.preimage f.f
#align category_theory.reflective.comparison_full CategoryTheory.Reflective.comparisonFull

end Reflective

-- It is possible to do this computably since the construction gives the data of the inverse, not
-- just the existence of an inverse on each object.
-- see Note [lower instance priority]
/-- Any reflective inclusion has a monadic right adjoint.
    cf Prop 5.3.3 of [Riehl][riehl2017] -/
noncomputable instance (priority := 100) monadicOfReflective [Reflective R] : MonadicRightAdjoint R
    where eqv := Equivalence.ofFullyFaithfullyEssSurj _
#align category_theory.monadic_of_reflective CategoryTheory.monadicOfReflective

end CategoryTheory
