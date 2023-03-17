/-
Copyright (c) 2021 Markus Himmel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Markus Himmel

! This file was ported from Lean 3 source module category_theory.monoidal.free.basic
! leanprover-community/mathlib commit 14b69e9f3c16630440a2cbd46f1ddad0d561dee7
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.CategoryTheory.Monoidal.Functor

/-!
# The free monoidal category over a type

Given a type `C`, the free monoidal category over `C` has as objects formal expressions built from
(formal) tensor products of terms of `C` and a formal unit. Its morphisms are compositions and
tensor products of identities, unitors and associators.

In this file, we construct the free monoidal category and prove that it is a monoidal category. If
`D` is a monoidal category, we construct the functor `free_monoidal_category C ⥤ D` associated to
a function `C → D`.

The free monoidal category has two important properties: it is a groupoid and it is thin. The former
is obvious from the construction, and the latter is what is commonly known as the monoidal coherence
theorem. Both of these properties are proved in the file `coherence.lean`.

-/


universe v' u u'

namespace CategoryTheory

open MonoidalCategory

variable {C : Type u}

section

variable (C)

/--
Given a type `C`, the free monoidal category over `C` has as objects formal expressions built from
(formal) tensor products of terms of `C` and a formal unit. Its morphisms are compositions and
tensor products of identities, unitors and associators.
-/
inductive FreeMonoidalCategory : Type u
  | of : C → FreeMonoidalCategory
  | Unit : FreeMonoidalCategory
  | tensor : FreeMonoidalCategory → FreeMonoidalCategory → FreeMonoidalCategory
  deriving Inhabited
#align category_theory.free_monoidal_category CategoryTheory.FreeMonoidalCategory

end

-- mathport name: exprF
local notation "F" => FreeMonoidalCategory

namespace FreeMonoidalCategory

/-- Formal compositions and tensor products of identities, unitors and associators. The morphisms
    of the free monoidal category are obtained as a quotient of these formal morphisms by the
    relations defining a monoidal category. -/
-- porting note: unsupported linter
-- @[nolint has_nonempty_instance]
inductive Hom : F C → F C → Type u
  | id (X) : Hom X X
  | α_hom (X Y Z : F C) : Hom ((X.tensor Y).tensor Z) (X.tensor (Y.tensor Z))
  | α_inv (X Y Z : F C) : Hom (X.tensor (Y.tensor Z)) ((X.tensor Y).tensor Z)
  | l_hom (X) : Hom (Unit.tensor X) X
  | l_inv (X) : Hom X (Unit.tensor X)
  | ρ_hom (X : F C) : Hom (X.tensor Unit) X
  | ρ_inv (X : F C) : Hom X (X.tensor Unit)
  | comp {X Y Z} (f : Hom X Y) (g : Hom Y Z) : Hom X Z
  | tensor {W X Y Z} (f : Hom W Y) (g : Hom X Z) : Hom (W.tensor X) (Y.tensor Z)
#align category_theory.free_monoidal_category.hom CategoryTheory.FreeMonoidalCategory.Hom

-- mathport name: «expr ⟶ᵐ »
local infixr:10 " ⟶ᵐ " => Hom

/-- The morphisms of the free monoidal category satisfy 21 relations ensuring that the resulting
    category is in fact a category and that it is monoidal. -/
inductive HomEquiv : ∀ {X Y : F C}, (X ⟶ᵐ Y) → (X ⟶ᵐ Y) → Prop
  | refl {X Y} (f : X ⟶ᵐ Y) : HomEquiv f f
  | symm {X Y} (f g : X ⟶ᵐ Y) : HomEquiv f g → HomEquiv g f
  | trans {X Y} {f g h : X ⟶ᵐ Y} : HomEquiv f g → HomEquiv g h → HomEquiv f h
  |
  comp {X Y Z} {f f' : X ⟶ᵐ Y} {g g' : Y ⟶ᵐ Z} :
    HomEquiv f f' → HomEquiv g g' → HomEquiv (f.comp g) (f'.comp g')
  |
  tensor {W X Y Z} {f f' : W ⟶ᵐ X} {g g' : Y ⟶ᵐ Z} :
    HomEquiv f f' → HomEquiv g g' → HomEquiv (f.tensor g) (f'.tensor g')
  | comp_id {X Y} (f : X ⟶ᵐ Y) : HomEquiv (f.comp (Hom.id _)) f
  | id_comp {X Y} (f : X ⟶ᵐ Y) : HomEquiv ((Hom.id _).comp f) f
  |
  assoc {X Y U V : F C} (f : X ⟶ᵐ U) (g : U ⟶ᵐ V) (h : V ⟶ᵐ Y) :
    HomEquiv ((f.comp g).comp h) (f.comp (g.comp h))
  | tensor_id {X Y} : HomEquiv ((Hom.id X).tensor (Hom.id Y)) (Hom.id _)
  |
  tensor_comp {X₁ Y₁ Z₁ X₂ Y₂ Z₂ : F C} (f₁ : X₁ ⟶ᵐ Y₁) (f₂ : X₂ ⟶ᵐ Y₂) (g₁ : Y₁ ⟶ᵐ Z₁)
    (g₂ : Y₂ ⟶ᵐ Z₂) :
    HomEquiv ((f₁.comp g₁).tensor (f₂.comp g₂)) ((f₁.tensor f₂).comp (g₁.tensor g₂))
  | α_hom_inv {X Y Z} : HomEquiv ((Hom.α_hom X Y Z).comp (Hom.α_inv X Y Z)) (Hom.id _)
  | α_inv_hom {X Y Z} : HomEquiv ((Hom.α_inv X Y Z).comp (Hom.α_hom X Y Z)) (Hom.id _)
  |
  associator_naturality {X₁ X₂ X₃ Y₁ Y₂ Y₃} (f₁ : X₁ ⟶ᵐ Y₁) (f₂ : X₂ ⟶ᵐ Y₂) (f₃ : X₃ ⟶ᵐ Y₃) :
    HomEquiv (((f₁.tensor f₂).tensor f₃).comp (Hom.α_hom Y₁ Y₂ Y₃))
      ((Hom.α_hom X₁ X₂ X₃).comp (f₁.tensor (f₂.tensor f₃)))
  | ρ_hom_inv {X} : HomEquiv ((Hom.ρ_hom X).comp (Hom.ρ_inv X)) (Hom.id _)
  | ρ_inv_hom {X} : HomEquiv ((Hom.ρ_inv X).comp (Hom.ρ_hom X)) (Hom.id _)
  |
  ρ_naturality {X Y} (f : X ⟶ᵐ Y) :
    HomEquiv ((f.tensor (Hom.id Unit)).comp (Hom.ρ_hom Y)) ((Hom.ρ_hom X).comp f)
  | l_hom_inv {X} : HomEquiv ((Hom.l_hom X).comp (Hom.l_inv X)) (Hom.id _)
  | l_inv_hom {X} : HomEquiv ((Hom.l_inv X).comp (Hom.l_hom X)) (Hom.id _)
  |
  l_naturality {X Y} (f : X ⟶ᵐ Y) :
    HomEquiv (((Hom.id Unit).tensor f).comp (Hom.l_hom Y)) ((Hom.l_hom X).comp f)
  |
  pentagon {W X Y Z} :
    HomEquiv
      (((Hom.α_hom W X Y).tensor (Hom.id Z)).comp
        ((Hom.α_hom W (X.tensor Y) Z).comp ((Hom.id W).tensor (Hom.α_hom X Y Z))))
      ((Hom.α_hom (W.tensor X) Y Z).comp (Hom.α_hom W X (Y.tensor Z)))
  |
  triangle {X Y} :
    HomEquiv ((Hom.α_hom X Unit Y).comp ((Hom.id X).tensor (Hom.l_hom Y)))
      ((Hom.ρ_hom X).tensor (Hom.id Y))
set_option linter.uppercaseLean3 false
#align category_theory.free_monoidal_category.HomEquiv CategoryTheory.FreeMonoidalCategory.HomEquiv

/-- We say that two formal morphisms in the free monoidal category are equivalent if they become
    equal if we apply the relations that are true in a monoidal category. Note that we will prove
    that there is only one equivalence class -- this is the monoidal coherence theorem. -/
def setoidHom (X Y : F C) : Setoid (X ⟶ᵐ Y) :=
  ⟨HomEquiv,
    ⟨fun f => HomEquiv.refl f, @fun f g => HomEquiv.symm f g, @fun _ _ _ hfg hgh =>
      HomEquiv.trans hfg hgh⟩⟩
#align category_theory.free_monoidal_category.setoid_hom CategoryTheory.FreeMonoidalCategory.setoidHom

attribute [instance] setoidHom

section

open FreeMonoidalCategory.HomEquiv

instance categoryFreeMonoidalCategory : Category.{u} (F C)
    where
  Hom X Y := Quotient (FreeMonoidalCategory.setoidHom X Y)
  id X := ⟦FreeMonoidalCategory.Hom.id _⟧
  comp := @fun X Y Z f g =>
    Quotient.map₂ Hom.comp
      (by
        intro f f' hf g g' hg
        exact comp hf hg)
      f g
  id_comp := by
    rintro X Y ⟨f⟩
    exact Quotient.sound (id_comp f)
  comp_id := by
    rintro X Y ⟨f⟩
    exact Quotient.sound (comp_id f)
  assoc := by
    rintro W X Y Z ⟨f⟩ ⟨g⟩ ⟨h⟩
    exact Quotient.sound (assoc f g h)
#align category_theory.free_monoidal_category.category_free_monoidal_category CategoryTheory.FreeMonoidalCategory.categoryFreeMonoidalCategory

instance : MonoidalCategory (F C)
    where
  tensorObj X Y := FreeMonoidalCategory.tensor X Y
  tensorHom := @fun X₁ Y₁ X₂ Y₂ =>
    Quotient.map₂ Hom.tensor <| by
      intro _ _ h _ _ h'
      exact HomEquiv.tensor h h'
  tensor_id X Y := Quotient.sound tensor_id
  tensor_comp := @fun X₁ Y₁ Z₁ X₂ Y₂ Z₂ => by
    rintro ⟨f₁⟩ ⟨f₂⟩ ⟨g₁⟩ ⟨g₂⟩
    exact Quotient.sound (tensor_comp _ _ _ _)
  tensorUnit' := FreeMonoidalCategory.Unit
  associator X Y Z :=
    ⟨⟦Hom.α_hom X Y Z⟧, ⟦Hom.α_inv X Y Z⟧, Quotient.sound α_hom_inv, Quotient.sound α_inv_hom⟩
  associator_naturality := @fun X₁ X₂ X₃ Y₁ Y₂ Y₃ =>
    by
    rintro ⟨f₁⟩ ⟨f₂⟩ ⟨f₃⟩
    exact Quotient.sound (associator_naturality _ _ _)
  leftUnitor X := ⟨⟦Hom.l_hom X⟧, ⟦Hom.l_inv X⟧, Quotient.sound l_hom_inv, Quotient.sound l_inv_hom⟩
  leftUnitor_naturality := @fun X Y => by
    rintro ⟨f⟩
    exact Quotient.sound (l_naturality _)
  rightUnitor X :=
    ⟨⟦Hom.ρ_hom X⟧, ⟦Hom.ρ_inv X⟧, Quotient.sound ρ_hom_inv, Quotient.sound ρ_inv_hom⟩
  rightUnitor_naturality := @fun X Y => by
    rintro ⟨f⟩
    exact Quotient.sound (ρ_naturality _)
  pentagon W X Y Z := Quotient.sound pentagon
  triangle X Y := Quotient.sound triangle

@[simp]
theorem mk'_comp {X Y Z : F C} (f : X ⟶ᵐ Y) (g : Y ⟶ᵐ Z) :
    ⟦f.comp g⟧ = @CategoryStruct.comp (F C) _ _ _ _ ⟦f⟧ ⟦g⟧ :=
  rfl
#align category_theory.free_monoidal_category.mk_comp CategoryTheory.FreeMonoidalCategory.mk'_comp

@[simp]
theorem mk'_tensor {X₁ Y₁ X₂ Y₂ : F C} (f : X₁ ⟶ᵐ Y₁) (g : X₂ ⟶ᵐ Y₂) :
    ⟦f.tensor g⟧ = @MonoidalCategory.tensorHom (F C) _ _ _ _ _ _ ⟦f⟧ ⟦g⟧ :=
  rfl
#align category_theory.free_monoidal_category.mk_tensor CategoryTheory.FreeMonoidalCategory.mk'_tensor

@[simp]
theorem mk'_id {X : F C} : ⟦Hom.id X⟧ = 𝟙 X :=
  rfl
#align category_theory.free_monoidal_category.mk_id CategoryTheory.FreeMonoidalCategory.mk'_id

@[simp]
theorem mk'_α_hom {X Y Z : F C} : ⟦Hom.α_hom X Y Z⟧ = (α_ X Y Z).hom :=
  rfl
#align category_theory.free_monoidal_category.mk_α_hom CategoryTheory.FreeMonoidalCategory.mk'_α_hom

@[simp]
theorem mk'_α_inv {X Y Z : F C} : ⟦Hom.α_inv X Y Z⟧ = (α_ X Y Z).inv :=
  rfl
#align category_theory.free_monoidal_category.mk_α_inv CategoryTheory.FreeMonoidalCategory.mk'_α_inv

@[simp]
theorem mk'_ρ_hom {X : F C} : ⟦Hom.ρ_hom X⟧ = (ρ_ X).hom :=
  rfl
#align category_theory.free_monoidal_category.mk_ρ_hom CategoryTheory.FreeMonoidalCategory.mk'_ρ_hom

@[simp]
theorem mk'_ρ_inv {X : F C} : ⟦Hom.ρ_inv X⟧ = (ρ_ X).inv :=
  rfl
#align category_theory.free_monoidal_category.mk_ρ_inv CategoryTheory.FreeMonoidalCategory.mk'_ρ_inv

@[simp]
theorem mk'_l_hom {X : F C} : ⟦Hom.l_hom X⟧ = (λ_ X).hom :=
  rfl
#align category_theory.free_monoidal_category.mk_l_hom CategoryTheory.FreeMonoidalCategory.mk'_l_hom

@[simp]
theorem mk'_l_inv {X : F C} : ⟦Hom.l_inv X⟧ = (λ_ X).inv :=
  rfl
#align category_theory.free_monoidal_category.mk_l_inv CategoryTheory.FreeMonoidalCategory.mk'_l_inv

/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
@[simp]
theorem tensor_eq_tensor {X Y : F C} : X.tensor Y = X ⊗ Y :=
  rfl
#align category_theory.free_monoidal_category.tensor_eq_tensor CategoryTheory.FreeMonoidalCategory.tensor_eq_tensor

@[simp]
theorem unit_eq_unit : FreeMonoidalCategory.Unit = 𝟙_ (F C) :=
  rfl
#align category_theory.free_monoidal_category.unit_eq_unit CategoryTheory.FreeMonoidalCategory.unit_eq_unit

section Functor

variable {D : Type u'} [Category.{v'} D] [MonoidalCategory D] (f : C → D)

/- warning: category_theory.free_monoidal_category.project_obj -> CategoryTheory.FreeMonoidalCategory.projectObj is a dubious translation:
lean 3 declaration is
  forall {C : Type.{u2}} {D : Type.{u3}} [_inst_1 : CategoryTheory.Category.{u1, u3} D] [_inst_2 : CategoryTheory.MonoidalCategory.{u1, u3} D _inst_1], (C -> D) -> (CategoryTheory.FreeMonoidalCategory.{u2} C) -> D
but is expected to have type
  forall {C : Type.{u1}} {D : Type.{u2}} [_inst_1 : CategoryTheory.Category.{u3, u2} D] [_inst_2 : CategoryTheory.MonoidalCategory.{u3, u2} D _inst_1], (C -> D) -> (CategoryTheory.FreeMonoidalCategory.{u1} C) -> D
Case conversion may be inaccurate. Consider using '#align category_theory.free_monoidal_category.project_obj CategoryTheory.FreeMonoidalCategory.projectObjₓ'. -/
/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
/-- Auxiliary definition for `free_monoidal_category.project`. -/
def projectObj : F C → D
  | FreeMonoidalCategory.of X => f X
  | FreeMonoidalCategory.Unit => 𝟙_ D
  | FreeMonoidalCategory.tensor X Y => projectObj X ⊗ projectObj Y
#align category_theory.free_monoidal_category.project_obj CategoryTheory.FreeMonoidalCategory.projectObj

section

open Hom

/- warning: category_theory.free_monoidal_category.project_map_aux -> CategoryTheory.FreeMonoidalCategory.projectMapAux is a dubious translation:
lean 3 declaration is
  forall {C : Type.{u2}} {D : Type.{u3}} [_inst_1 : CategoryTheory.Category.{u1, u3} D] [_inst_2 : CategoryTheory.MonoidalCategory.{u1, u3} D _inst_1] (f : C -> D) {X : CategoryTheory.FreeMonoidalCategory.{u2} C} {Y : CategoryTheory.FreeMonoidalCategory.{u2} C}, (CategoryTheory.FreeMonoidalCategory.Hom.{u2} C X Y) -> (Quiver.Hom.{succ u1, u3} D (CategoryTheory.CategoryStruct.toQuiver.{u1, u3} D (CategoryTheory.Category.toCategoryStruct.{u1, u3} D _inst_1)) (CategoryTheory.FreeMonoidalCategory.projectObj.{u1, u2, u3} C D _inst_1 _inst_2 f X) (CategoryTheory.FreeMonoidalCategory.projectObj.{u1, u2, u3} C D _inst_1 _inst_2 f Y))
but is expected to have type
  PUnit.{max (max (succ (succ u1)) (succ (succ u2))) (succ (succ u3))}
Case conversion may be inaccurate. Consider using '#align category_theory.free_monoidal_category.project_map_aux CategoryTheory.FreeMonoidalCategory.projectMapAuxₓ'. -/
/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
/-- Auxiliary definition for `free_monoidal_category.project`. -/
@[simp]
def projectMapAux : ∀ {X Y : F C}, (X ⟶ᵐ Y) → (projectObj f X ⟶ projectObj f Y)
  | _, _, Hom.id _ => 𝟙 _
  | _, _, α_hom _ _ _ => (α_ _ _ _).hom
  | _, _, α_inv _ _ _ => (α_ _ _ _).inv
  | _, _, l_hom _ => (λ_ _).hom
  | _, _, l_inv _ => (λ_ _).inv
  | _, _, ρ_hom _ => (ρ_ _).hom
  | _, _, ρ_inv _ => (ρ_ _).inv
  | _, _, Hom.comp f g => projectMapAux f ≫ projectMapAux g
  | _, _, Hom.tensor f g => projectMapAux f ⊗ projectMapAux g
#align category_theory.free_monoidal_category.project_map_aux CategoryTheory.FreeMonoidalCategory.projectMapAux

/-- Auxiliary definition for `free_monoidal_category.project`. -/
def projectMap (X Y : F C) : (X ⟶ Y) → (projectObj f X ⟶ projectObj f Y) :=
  Quotient.lift (projectMapAux f)
    (by
      intro f g h
      induction' h with
        X Y f X Y f g _ hfg' X Y f g h _ _ hfg hgh X Y Z f f' g g' _ _ hf hg W X Y Z f g f' g' _ _ hfg hfg'
      · rfl
      · exact hfg'.symm
      · exact hfg.trans hgh
      · simp only [projectMapAux, hf, hg]
      · simp only [projectMapAux, hfg, hfg']
      · simp only [projectMapAux, Category.comp_id]
      · simp only [projectMapAux, Category.id_comp]
      · simp only [projectMapAux, Category.assoc]
      · simp only [projectMapAux, MonoidalCategory.tensor_id]
        rfl
      · simp only [projectMapAux, MonoidalCategory.tensor_comp]
      · simp only [projectMapAux, Iso.hom_inv_id]
      · simp only [projectMapAux, Iso.inv_hom_id]
      · simp only [projectMapAux, MonoidalCategory.associator_naturality]
      · simp only [projectMapAux, Iso.hom_inv_id]
      · simp only [projectMapAux, Iso.inv_hom_id]
      · simp only [projectMapAux]
        dsimp [projectObj]
        exact MonoidalCategory.rightUnitor_naturality _
      · simp only [projectMapAux, Iso.hom_inv_id]
      · simp only [projectMapAux, Iso.inv_hom_id]
      · simp only [projectMapAux]
        dsimp [projectObj]
        exact MonoidalCategory.leftUnitor_naturality _
      · simp only [projectMapAux]
        exact MonoidalCategory.pentagon _ _ _ _
      · simp only [projectMapAux]
        exact MonoidalCategory.triangle _ _)
#align category_theory.free_monoidal_category.project_map CategoryTheory.FreeMonoidalCategory.projectMap

end

/-- If `D` is a monoidal category and we have a function `C → D`, then we have a functor from the
    free monoidal category over `C` to the category `D`. -/
def project : MonoidalFunctor (F C) D
    where
  obj := projectObj f
  map := @fun X Y => projectMap f X Y
  ε := 𝟙 _
  μ := fun X Y => 𝟙 _
#align category_theory.free_monoidal_category.project CategoryTheory.FreeMonoidalCategory.project

end Functor

end

end FreeMonoidalCategory

end CategoryTheory
