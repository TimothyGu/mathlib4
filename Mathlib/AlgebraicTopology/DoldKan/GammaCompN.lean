/-
Copyright (c) 2022 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou

! This file was ported from Lean 3 source module algebraic_topology.dold_kan.gamma_comp_n
! leanprover-community/mathlib commit 5f68029a863bdf76029fa0f7a519e6163c14152e
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.AlgebraicTopology.DoldKan.FunctorGamma
import Mathlib.CategoryTheory.Idempotents.HomologicalComplex

/-! The counit isomorphism of the Dold-Kan equivalence

The purpose of this file is to construct natural isomorphisms
`N₁Γ₀ : Γ₀ ⋙ N₁ ≅ toKaroubi (ChainComplex C ℕ)`
and `N₂Γ₂ : Γ₂ ⋙ N₂ ≅ 𝟭 (Karoubi (ChainComplex C ℕ))`.

-/


noncomputable section

open CategoryTheory CategoryTheory.Category CategoryTheory.Limits
  CategoryTheory.Idempotents Opposite SimplicialObject Simplicial

namespace AlgebraicTopology

namespace DoldKan

variable {C : Type _} [Category C] [Preadditive C] [HasFiniteCoproducts C]

/-- The isomorphism  `(Γ₀.splitting K).nondegComplex ≅ K` for all `K : ChainComplex C ℕ`. -/
@[simps!]
def Γ₀NondegComplexIso (K : ChainComplex C ℕ) : (Γ₀.splitting K).nondegComplex ≅ K :=
  HomologicalComplex.Hom.isoOfComponents (fun n => Iso.refl _)
    (by
      rintro _ n (rfl : n + 1 = _)
      dsimp
      simp only [id_comp, comp_id, AlternatingFaceMapComplex.obj_d_eq, Preadditive.sum_comp,
        Preadditive.comp_sum]
      rw [Fintype.sum_eq_single (0 : Fin (n + 2))]
      · simp only [Fin.val_zero, pow_zero, one_zsmul]
        erw [Γ₀.Obj.mapMono_on_summand_id_assoc, Γ₀.Obj.Termwise.mapMono_δ₀,
          Splitting.ι_πSummand_eq_id, comp_id]
      · intro i hi
        dsimp
        simp only [Preadditive.zsmul_comp, Preadditive.comp_zsmul, assoc]
        erw [Γ₀.Obj.mapMono_on_summand_id_assoc, Γ₀.Obj.Termwise.mapMono_eq_zero, zero_comp,
          zsmul_zero]
        · intro h
          replace h := congr_arg SimplexCategory.len h
          change n + 1 = n at h
          linarith
        · simpa only [Isδ₀.iff] using hi)
#align algebraic_topology.dold_kan.Γ₀_nondeg_complex_iso AlgebraicTopology.DoldKan.Γ₀NondegComplexIso

/-- The natural isomorphism `(Γ₀.splitting K).nondegComplex ≅ K` for `K : ChainComplex C ℕ`. -/
def Γ₀'CompNondegComplexFunctor : Γ₀' ⋙ Split.nondegComplexFunctor ≅ 𝟭 (ChainComplex C ℕ) :=
  NatIso.ofComponents Γ₀NondegComplexIso (by aesop_cat)
#align algebraic_topology.dold_kan.Γ₀'_comp_nondeg_complex_functor AlgebraicTopology.DoldKan.Γ₀'CompNondegComplexFunctor

/-- The natural isomorphism `Γ₀ ⋙ N₁ ≅ toKaroubi (ChainComplex C ℕ)`. -/
def N₁Γ₀ : Γ₀ ⋙ N₁ ≅ toKaroubi (ChainComplex C ℕ) :=
  calc
    Γ₀ ⋙ N₁ ≅ Γ₀' ⋙ Split.forget C ⋙ N₁ := Functor.associator _ _ _
    _ ≅ Γ₀' ⋙ Split.nondegComplexFunctor ⋙ toKaroubi _ :=
      (isoWhiskerLeft Γ₀' Split.toKaroubiNondegComplexFunctorIsoN₁.symm)
    _ ≅ (Γ₀' ⋙ Split.nondegComplexFunctor) ⋙ toKaroubi _ := (Functor.associator _ _ _).symm
    _ ≅ 𝟭 _ ⋙ toKaroubi (ChainComplex C ℕ) := (isoWhiskerRight Γ₀'CompNondegComplexFunctor _)
    _ ≅ toKaroubi (ChainComplex C ℕ) := Functor.leftUnitor _
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀ AlgebraicTopology.DoldKan.N₁Γ₀

theorem N₁Γ₀_app (K : ChainComplex C ℕ) :
    N₁Γ₀.app K = (Γ₀.splitting K).toKaroubiNondegComplexIsoN₁.symm ≪≫
      (toKaroubi _).mapIso (Γ₀NondegComplexIso K) := by
  ext1
  dsimp [N₁Γ₀]
  erw [id_comp, comp_id, comp_id]
  rfl
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀_app AlgebraicTopology.DoldKan.N₁Γ₀_app

theorem N₁Γ₀_hom_app (K : ChainComplex C ℕ) :
    N₁Γ₀.hom.app K = (Γ₀.splitting K).toKaroubiNondegComplexIsoN₁.inv ≫
        (toKaroubi _).map (Γ₀NondegComplexIso K).hom := by
  change (N₁Γ₀.app K).hom = _
  simp only [N₁Γ₀_app]
  rfl
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀_hom_app AlgebraicTopology.DoldKan.N₁Γ₀_hom_app

theorem N₁Γ₀_inv_app (K : ChainComplex C ℕ) :
    N₁Γ₀.inv.app K = (toKaroubi _).map (Γ₀NondegComplexIso K).inv ≫
        (Γ₀.splitting K).toKaroubiNondegComplexIsoN₁.hom := by
  change (N₁Γ₀.app K).inv = _
  simp only [N₁Γ₀_app]
  rfl
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀_inv_app AlgebraicTopology.DoldKan.N₁Γ₀_inv_app

@[simp]
theorem N₁Γ₀_hom_app_f_f (K : ChainComplex C ℕ) (n : ℕ) :
    (N₁Γ₀.hom.app K).f.f n = (Γ₀.splitting K).toKaroubiNondegComplexIsoN₁.inv.f.f n := by
  rw [N₁Γ₀_hom_app]
  apply comp_id
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀_hom_app_f_f AlgebraicTopology.DoldKan.N₁Γ₀_hom_app_f_f

@[simp]
theorem N₁Γ₀_inv_app_f_f (K : ChainComplex C ℕ) (n : ℕ) :
    (N₁Γ₀.inv.app K).f.f n = (Γ₀.splitting K).toKaroubiNondegComplexIsoN₁.hom.f.f n := by
  rw [N₁Γ₀_inv_app]
  apply id_comp
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₁Γ₀_inv_app_f_f AlgebraicTopology.DoldKan.N₁Γ₀_inv_app_f_f

theorem N₂Γ₂_toKaroubi : toKaroubi (ChainComplex C ℕ) ⋙ Γ₂ ⋙ N₂ = Γ₀ ⋙ N₁ := by
  have h := Functor.congr_obj (functorExtension₂_comp_whiskeringLeft_toKaroubi
    (ChainComplex C ℕ) (SimplicialObject C)) Γ₀
  have h' := Functor.congr_obj (functorExtension₁_comp_whiskeringLeft_toKaroubi
    (SimplicialObject C) (ChainComplex C ℕ)) N₁
  dsimp [N₂, Γ₂, functorExtension₁] at h h' ⊢
  rw [← Functor.assoc, h, Functor.assoc, h']
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₂Γ₂_to_karoubi AlgebraicTopology.DoldKan.N₂Γ₂_toKaroubi

/-- Compatibility isomorphism between `toKaroubi _ ⋙ Γ₂ ⋙ N₂` and `Γ₀ ⋙ N₁` which
are functors `ChainComplex C ℕ ⥤ Karoubi (ChainComplex C ℕ)`. -/
@[simps!]
def N₂Γ₂ToKaroubiIso : toKaroubi (ChainComplex C ℕ) ⋙ Γ₂ ⋙ N₂ ≅ Γ₀ ⋙ N₁ :=
  eqToIso N₂Γ₂_toKaroubi
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₂Γ₂_to_karoubi_iso AlgebraicTopology.DoldKan.N₂Γ₂ToKaroubiIso

/-- The counit isomorphism of the Dold-Kan equivalence for additive categories. -/
def N₂Γ₂ : Γ₂ ⋙ N₂ ≅ 𝟭 (Karoubi (ChainComplex C ℕ)) :=
  ((whiskeringLeft _ _ _).obj (toKaroubi (ChainComplex C ℕ))).preimageIso
      (N₂Γ₂ToKaroubiIso ≪≫ N₁Γ₀)
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₂Γ₂ AlgebraicTopology.DoldKan.N₂Γ₂

-- porting note: added to ease the proof of `N₂Γ₂_compatible_with_N₁Γ₀`
lemma whiskerLeft_toKaroubi_N₂Γ₂_hom :
    whiskerLeft (toKaroubi (ChainComplex C ℕ)) N₂Γ₂.hom = N₂Γ₂ToKaroubiIso.hom ≫ N₁Γ₀.hom := by
  let e : _ ≅ toKaroubi (ChainComplex C ℕ) ⋙ 𝟭 _ := N₂Γ₂ToKaroubiIso ≪≫ N₁Γ₀
  have h := ((whiskeringLeft _ _ (Karoubi (ChainComplex C ℕ))).obj
    (toKaroubi (ChainComplex C ℕ))).image_preimage e.hom
  dsimp only [whiskeringLeft, N₂Γ₂, Functor.preimageIso] at h ⊢
  exact h

theorem N₂Γ₂_compatible_with_N₁Γ₀ (K : ChainComplex C ℕ) :
    N₂Γ₂.hom.app ((toKaroubi _).obj K) = N₂Γ₂ToKaroubiIso.hom.app K ≫ N₁Γ₀.hom.app K := by
  have h := congr_app whiskerLeft_toKaroubi_N₂Γ₂_hom K
  simp only [whiskerLeft, NatTrans.comp_app] at h
  -- porting note: `exact h` causes a timeout
  rw [h]
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₂Γ₂_compatible_with_N₁Γ₀ AlgebraicTopology.DoldKan.N₂Γ₂_compatible_with_N₁Γ₀

@[simp]
theorem N₂Γ₂_inv_app_f_f (X : Karoubi (ChainComplex C ℕ)) (n : ℕ) :
    (N₂Γ₂.inv.app X).f.f n =
      X.p.f n ≫ (Γ₀.splitting X.X).ιSummand (Splitting.IndexSet.id (op [n])) := by
  sorry
  --dsimp only [N₂Γ₂, functor.preimage_iso, iso.trans]
  --simp only [whiskering_left_obj_preimage_app, N₂Γ₂_to_karoubi_iso_inv, functor.id_map,
  --  nat_trans.comp_app, eq_to_hom_app, functor.comp_map, assoc, karoubi.comp_f, karoubi.eq_to_hom_f,
  --  eq_to_hom_refl, comp_id, karoubi.comp_p_assoc, N₂_map_f_f, HomologicalComplex.comp_f,
  --  N₁Γ₀_inv_app_f_f, P_infty_on_Γ₀_splitting_summand_eq_self_assoc,
  --  splitting.to_karoubi_nondeg_complex_iso_N₁_hom_f_f, Γ₂_map_f_app, karoubi.decomp_id_p_f]
  --dsimp [to_karoubi]
  --rw [splitting.ι_desc]
  --dsimp [splitting.index_set.id]
  --rw [karoubi.homological_complex.p_idem_assoc]
set_option linter.uppercaseLean3 false in
#align algebraic_topology.dold_kan.N₂Γ₂_inv_app_f_f AlgebraicTopology.DoldKan.N₂Γ₂_inv_app_f_f

end DoldKan

end AlgebraicTopology
