/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro

! This file was ported from Lean 3 source module measure_theory.measure.measure_space
! leanprover-community/mathlib commit 88fcb83fe7996142dfcfe7368d31304a9adc874a
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.MeasureTheory.Measure.NullMeasurable
import Mathlib.MeasureTheory.MeasurableSpace
import Mathlib.Topology.Algebra.Order.LiminfLimsup
import Mathlib.Tactic

/-!
# Measure spaces

The definition of a measure and a measure space are in `measure_theory.measure_space_def`, with
only a few basic properties. This file provides many more properties of these objects.
This separation allows the measurability tactic to import only the file `measure_space_def`, and to
be available in `measure_space` (through `measurable_space`).

Given a measurable space `α`, a measure on `α` is a function that sends measurable sets to the
extended nonnegative reals that satisfies the following conditions:
1. `μ ∅ = 0`;
2. `μ` is countably additive. This means that the measure of a countable union of pairwise disjoint
   sets is equal to the measure of the individual sets.

Every measure can be canonically extended to an outer measure, so that it assigns values to
all subsets, not just the measurable subsets. On the other hand, a measure that is countably
additive on measurable sets can be restricted to measurable sets to obtain a measure.
In this file a measure is defined to be an outer measure that is countably additive on
measurable sets, with the additional assumption that the outer measure is the canonical
extension of the restricted measure.

Measures on `α` form a complete lattice, and are closed under scalar multiplication with `ℝ≥0∞`.

We introduce the following typeclasses for measures:

* `is_probability_measure μ`: `μ univ = 1`;
* `is_finite_measure μ`: `μ univ < ∞`;
* `sigma_finite μ`: there exists a countable collection of sets that cover `univ`
  where `μ` is finite;
* `is_locally_finite_measure μ` : `∀ x, ∃ s ∈ 𝓝 x, μ s < ∞`;
* `has_no_atoms μ` : `∀ x, μ {x} = 0`; possibly should be redefined as
  `∀ s, 0 < μ s → ∃ t ⊆ s, 0 < μ t ∧ μ t < μ s`.

Given a measure, the null sets are the sets where `μ s = 0`, where `μ` denotes the corresponding
outer measure (so `s` might not be measurable). We can then define the completion of `μ` as the
measure on the least `σ`-algebra that also contains all null sets, by defining the measure to be `0`
on the null sets.

## Main statements

* `completion` is the completion of a measure to all null measurable sets.
* `measure.of_measurable` and `outer_measure.to_measure` are two important ways to define a measure.

## Implementation notes

Given `μ : measure α`, `μ s` is the value of the *outer measure* applied to `s`.
This conveniently allows us to apply the measure to sets without proving that they are measurable.
We get countable subadditivity for all sets, but only countable additivity for measurable sets.

You often don't want to define a measure via its constructor.
Two ways that are sometimes more convenient:
* `measure.of_measurable` is a way to define a measure by only giving its value on measurable sets
  and proving the properties (1) and (2) mentioned above.
* `outer_measure.to_measure` is a way of obtaining a measure from an outer measure by showing that
  all measurable sets in the measurable space are Carathéodory measurable.

To prove that two measures are equal, there are multiple options:
* `ext`: two measures are equal if they are equal on all measurable sets.
* `ext_of_generate_from_of_Union`: two measures are equal if they are equal on a π-system generating
  the measurable sets, if the π-system contains a spanning increasing sequence of sets where the
  measures take finite value (in particular the measures are σ-finite). This is a special case of
  the more general `ext_of_generate_from_of_cover`
* `ext_of_generate_finite`: two finite measures are equal if they are equal on a π-system
  generating the measurable sets. This is a special case of `ext_of_generate_from_of_Union` using
  `C ∪ {univ}`, but is easier to work with.

A `measure_space` is a class that is a measurable space with a canonical measure.
The measure is denoted `volume`.

## References

* <https://en.wikipedia.org/wiki/Measure_(mathematics)>
* <https://en.wikipedia.org/wiki/Complete_measure>
* <https://en.wikipedia.org/wiki/Almost_everywhere>

## Tags

measure, almost everywhere, measure space, completion, null set, null measurable set
-/


noncomputable section

open Set

open Filter hiding map

open Function MeasurableSpace

open TopologicalSpace (SecondCountableTopology)

open Classical Topology BigOperators Filter ENNReal NNReal Interval MeasureTheory

variable {α β γ δ ι R R' : Type _}

namespace MeasureTheory

section

variable {m : MeasurableSpace α} {μ μ₁ μ₂ : Measure α} {s s₁ s₂ t : Set α}

instance ae_isMeasurablyGenerated : IsMeasurablyGenerated μ.ae :=
  ⟨fun s hs =>
    let ⟨t, hst, htm, htμ⟩ := exists_measurable_superset_of_null hs
    ⟨tᶜ, compl_mem_ae_iff.2 htμ, htm.compl, compl_subset_comm.1 hst⟩⟩
#align measure_theory.ae_is_measurably_generated MeasureTheory.ae_isMeasurablyGenerated

/-- See also `measure_theory.ae_restrict_uIoc_iff`. -/
theorem ae_uIoc_iff [LinearOrder α] {a b : α} {P : α → Prop} :
    (∀ᵐ x ∂μ, x ∈ Ι a b → P x) ↔ (∀ᵐ x ∂μ, x ∈ Ioc a b → P x) ∧ ∀ᵐ x ∂μ, x ∈ Ioc b a → P x := by
  simp only [uIoc_eq_union, mem_union, or_imp, eventually_and]
#align measure_theory.ae_uIoc_iff MeasureTheory.ae_uIoc_iff

theorem measure_union (hd : Disjoint s₁ s₂) (h : MeasurableSet s₂) : μ (s₁ ∪ s₂) = μ s₁ + μ s₂ :=
  measure_union₀ h.nullMeasurableSet hd.AeDisjoint
#align measure_theory.measure_union MeasureTheory.measure_union

theorem measure_union' (hd : Disjoint s₁ s₂) (h : MeasurableSet s₁) : μ (s₁ ∪ s₂) = μ s₁ + μ s₂ :=
  measure_union₀' h.nullMeasurableSet hd.AeDisjoint
#align measure_theory.measure_union' MeasureTheory.measure_union'

theorem measure_inter_add_diff (s : Set α) (ht : MeasurableSet t) : μ (s ∩ t) + μ (s \ t) = μ s :=
  measure_inter_add_diff₀ _ ht.nullMeasurableSet
#align measure_theory.measure_inter_add_diff MeasureTheory.measure_inter_add_diff

theorem measure_diff_add_inter (s : Set α) (ht : MeasurableSet t) : μ (s \ t) + μ (s ∩ t) = μ s :=
  (add_comm _ _).trans (measure_inter_add_diff s ht)
#align measure_theory.measure_diff_add_inter MeasureTheory.measure_diff_add_inter

theorem measure_union_add_inter (s : Set α) (ht : MeasurableSet t) :
    μ (s ∪ t) + μ (s ∩ t) = μ s + μ t := by
  rw [← measure_inter_add_diff (s ∪ t) ht, Set.union_inter_cancel_right, union_diff_right, ←
    measure_inter_add_diff s ht]
  ac_rfl
#align measure_theory.measure_union_add_inter MeasureTheory.measure_union_add_inter

theorem measure_union_add_inter' (hs : MeasurableSet s) (t : Set α) :
    μ (s ∪ t) + μ (s ∩ t) = μ s + μ t := by
  rw [union_comm, inter_comm, measure_union_add_inter t hs, add_comm]
#align measure_theory.measure_union_add_inter' MeasureTheory.measure_union_add_inter'

theorem measure_add_measure_compl (h : MeasurableSet s) : μ s + μ (sᶜ) = μ univ :=
  measure_add_measure_compl₀ h.nullMeasurableSet
#align measure_theory.measure_add_measure_compl MeasureTheory.measure_add_measure_compl

theorem measure_bunionᵢ₀ {s : Set β} {f : β → Set α} (hs : s.Countable)
    (hd : s.Pairwise (AeDisjoint μ on f)) (h : ∀ b ∈ s, NullMeasurableSet (f b) μ) :
    μ (⋃ b ∈ s, f b) = ∑' p : s, μ (f p) := by
  haveI := hs.toEncodable
  rw [bunionᵢ_eq_unionᵢ]
  exact measure_unionᵢ₀ (hd.on_injective Subtype.coe_injective fun x => x.2) fun x => h x x.2
#align measure_theory.measure_bUnion₀ MeasureTheory.measure_bunionᵢ₀

theorem measure_bunionᵢ {s : Set β} {f : β → Set α} (hs : s.Countable) (hd : s.PairwiseDisjoint f)
    (h : ∀ b ∈ s, MeasurableSet (f b)) : μ (⋃ b ∈ s, f b) = ∑' p : s, μ (f p) :=
  measure_bunionᵢ₀ hs hd.AeDisjoint fun b hb => (h b hb).nullMeasurableSet
#align measure_theory.measure_bUnion MeasureTheory.measure_bunionᵢ

theorem measure_unionₛ₀ {S : Set (Set α)} (hs : S.Countable) (hd : S.Pairwise (AeDisjoint μ))
    (h : ∀ s ∈ S, NullMeasurableSet s μ) : μ (⋃₀ S) = ∑' s : S, μ s := by
  rw [unionₛ_eq_bunionᵢ, measure_bunionᵢ₀ hs hd h]
#align measure_theory.measure_sUnion₀ MeasureTheory.measure_unionₛ₀

theorem measure_unionₛ {S : Set (Set α)} (hs : S.Countable) (hd : S.Pairwise Disjoint)
    (h : ∀ s ∈ S, MeasurableSet s) : μ (⋃₀ S) = ∑' s : S, μ s := by
  rw [unionₛ_eq_bunionᵢ, measure_bunionᵢ hs hd h]
#align measure_theory.measure_sUnion MeasureTheory.measure_unionₛ

theorem measure_bunionᵢ_finset₀ {s : Finset ι} {f : ι → Set α}
    (hd : Set.Pairwise (↑s) (AeDisjoint μ on f)) (hm : ∀ b ∈ s, NullMeasurableSet (f b) μ) :
    μ (⋃ b ∈ s, f b) = ∑ p in s, μ (f p) := by
  rw [← Finset.sum_attach, Finset.attach_eq_univ, ← tsum_fintype]
  exact measure_bunionᵢ₀ s.countable_toSet hd hm
#align measure_theory.measure_bUnion_finset₀ MeasureTheory.measure_bunionᵢ_finset₀

theorem measure_bunionᵢ_finset {s : Finset ι} {f : ι → Set α} (hd : PairwiseDisjoint (↑s) f)
    (hm : ∀ b ∈ s, MeasurableSet (f b)) : μ (⋃ b ∈ s, f b) = ∑ p in s, μ (f p) :=
  measure_bunionᵢ_finset₀ hd.AeDisjoint fun b hb => (hm b hb).nullMeasurableSet
#align measure_theory.measure_bUnion_finset MeasureTheory.measure_bunionᵢ_finset

/-- The measure of a disjoint union (even uncountable) of measurable sets is at least the sum of
the measures of the sets. -/
theorem tsum_meas_le_meas_unionᵢ_of_disjoint {ι : Type _} [MeasurableSpace α] (μ : Measure α)
    {As : ι → Set α} (As_mble : ∀ i : ι, MeasurableSet (As i))
    (As_disj : Pairwise (Disjoint on As)) : (∑' i, μ (As i)) ≤ μ (⋃ i, As i) := by
  rcases show Summable fun i => μ (As i) from ENNReal.summable with ⟨S, hS⟩
  rw [hS.tsum_eq]
  refine' tendsto_le_of_eventuallyLE hS tendsto_const_nhds (eventually_of_forall _)
  intro s
  simp [← measure_bunionᵢ_finset (fun i hi j hj hij => As_disj hij) fun i _ => As_mble i]
  exact measure_mono (unionᵢ₂_subset_unionᵢ (fun i : ι => i ∈ s) fun i : ι => As i)
#align measure_theory.tsum_meas_le_meas_Union_of_disjoint MeasureTheory.tsum_meas_le_meas_unionᵢ_of_disjoint

/-- If `s` is a countable set, then the measure of its preimage can be found as the sum of measures
of the fibers `f ⁻¹' {y}`. -/
theorem tsum_measure_preimage_singleton {s : Set β} (hs : s.Countable) {f : α → β}
    (hf : ∀ y ∈ s, MeasurableSet (f ⁻¹' {y})) : (∑' b : s, μ (f ⁻¹' {↑b})) = μ (f ⁻¹' s) := by
  rw [← Set.bunionᵢ_preimage_singleton, measure_bunionᵢ hs (pairwiseDisjoint_fiber f s) hf]
#align measure_theory.tsum_measure_preimage_singleton MeasureTheory.tsum_measure_preimage_singleton

/-- If `s` is a `finset`, then the measure of its preimage can be found as the sum of measures
of the fibers `f ⁻¹' {y}`. -/
theorem sum_measure_preimage_singleton (s : Finset β) {f : α → β}
    (hf : ∀ y ∈ s, MeasurableSet (f ⁻¹' {y})) : (∑ b in s, μ (f ⁻¹' {b})) = μ (f ⁻¹' ↑s) := by
  simp only [← measure_bunionᵢ_finset (pairwiseDisjoint_fiber f s) hf,
    Finset.set_bunionᵢ_preimage_singleton]
#align measure_theory.sum_measure_preimage_singleton MeasureTheory.sum_measure_preimage_singleton

theorem measure_diff_null' (h : μ (s₁ ∩ s₂) = 0) : μ (s₁ \ s₂) = μ s₁ :=
  measure_congr <| diff_ae_eq_self.2 h
#align measure_theory.measure_diff_null' MeasureTheory.measure_diff_null'

theorem measure_diff_null (h : μ s₂ = 0) : μ (s₁ \ s₂) = μ s₁ :=
  measure_diff_null' <| measure_mono_null (inter_subset_right _ _) h
#align measure_theory.measure_diff_null MeasureTheory.measure_diff_null

theorem measure_add_diff (hs : MeasurableSet s) (t : Set α) : μ s + μ (t \ s) = μ (s ∪ t) := by
  rw [← measure_union' (@disjoint_sdiff_right _ s t) hs, union_diff_self]
#align measure_theory.measure_add_diff MeasureTheory.measure_add_diff

theorem measure_diff' (s : Set α) (hm : MeasurableSet t) (h_fin : μ t ≠ ∞) :
    μ (s \ t) = μ (s ∪ t) - μ t :=
  Eq.symm <| ENNReal.sub_eq_of_add_eq h_fin <| by rw [add_comm, measure_add_diff hm, union_comm]
#align measure_theory.measure_diff' MeasureTheory.measure_diff'

theorem measure_diff (h : s₂ ⊆ s₁) (h₂ : MeasurableSet s₂) (h_fin : μ s₂ ≠ ∞) :
    μ (s₁ \ s₂) = μ s₁ - μ s₂ := by rw [measure_diff' _ h₂ h_fin, union_eq_self_of_subset_right h]
#align measure_theory.measure_diff MeasureTheory.measure_diff

theorem le_measure_diff : μ s₁ - μ s₂ ≤ μ (s₁ \ s₂) :=
  tsub_le_iff_left.2 <|
    calc
      μ s₁ ≤ μ (s₂ ∪ s₁) := measure_mono (subset_union_right _ _)
      _ = μ (s₂ ∪ s₁ \ s₂) := (congr_arg μ union_diff_self.symm)
      _ ≤ μ s₂ + μ (s₁ \ s₂) := measure_union_le _ _

#align measure_theory.le_measure_diff MeasureTheory.le_measure_diff

theorem measure_diff_lt_of_lt_add (hs : MeasurableSet s) (hst : s ⊆ t) (hs' : μ s ≠ ∞) {ε : ℝ≥0∞}
    (h : μ t < μ s + ε) : μ (t \ s) < ε := by
  rw [measure_diff hst hs hs']; rw [add_comm] at h
  exact ENNReal.sub_lt_of_lt_add (measure_mono hst) h
#align measure_theory.measure_diff_lt_of_lt_add MeasureTheory.measure_diff_lt_of_lt_add

theorem measure_diff_le_iff_le_add (hs : MeasurableSet s) (hst : s ⊆ t) (hs' : μ s ≠ ∞) {ε : ℝ≥0∞} :
    μ (t \ s) ≤ ε ↔ μ t ≤ μ s + ε := by rw [measure_diff hst hs hs', tsub_le_iff_left]
#align measure_theory.measure_diff_le_iff_le_add MeasureTheory.measure_diff_le_iff_le_add

theorem measure_eq_measure_of_null_diff {s t : Set α} (hst : s ⊆ t) (h_nulldiff : μ (t \ s) = 0) :
    μ s = μ t := measure_congr <|
      EventuallyLE.antisymm (HasSubset.Subset.eventuallyLE hst) (ae_le_set.mpr h_nulldiff)
#align measure_theory.measure_eq_measure_of_null_diff MeasureTheory.measure_eq_measure_of_null_diff

theorem measure_eq_measure_of_between_null_diff {s₁ s₂ s₃ : Set α} (h12 : s₁ ⊆ s₂) (h23 : s₂ ⊆ s₃)
    (h_nulldiff : μ (s₃ \ s₁) = 0) : μ s₁ = μ s₂ ∧ μ s₂ = μ s₃ := by
  have le12 : μ s₁ ≤ μ s₂ := measure_mono h12
  have le23 : μ s₂ ≤ μ s₃ := measure_mono h23
  have key : μ s₃ ≤ μ s₁ :=
    calc
      μ s₃ = μ (s₃ \ s₁ ∪ s₁) := by rw [diff_union_of_subset (h12.trans h23)]
      _ ≤ μ (s₃ \ s₁) + μ s₁ := (measure_union_le _ _)
      _ = μ s₁ := by simp only [h_nulldiff, zero_add]

  exact ⟨le12.antisymm (le23.trans key), le23.antisymm (key.trans le12)⟩
#align measure_theory.measure_eq_measure_of_between_null_diff MeasureTheory.measure_eq_measure_of_between_null_diff

theorem measure_eq_measure_smaller_of_between_null_diff {s₁ s₂ s₃ : Set α} (h12 : s₁ ⊆ s₂)
    (h23 : s₂ ⊆ s₃) (h_nulldiff : μ (s₃ \ s₁) = 0) : μ s₁ = μ s₂ :=
  (measure_eq_measure_of_between_null_diff h12 h23 h_nulldiff).1
#align measure_theory.measure_eq_measure_smaller_of_between_null_diff MeasureTheory.measure_eq_measure_smaller_of_between_null_diff

theorem measure_eq_measure_larger_of_between_null_diff {s₁ s₂ s₃ : Set α} (h12 : s₁ ⊆ s₂)
    (h23 : s₂ ⊆ s₃) (h_nulldiff : μ (s₃ \ s₁) = 0) : μ s₂ = μ s₃ :=
  (measure_eq_measure_of_between_null_diff h12 h23 h_nulldiff).2
#align measure_theory.measure_eq_measure_larger_of_between_null_diff MeasureTheory.measure_eq_measure_larger_of_between_null_diff

theorem measure_compl (h₁ : MeasurableSet s) (h_fin : μ s ≠ ∞) : μ (sᶜ) = μ univ - μ s := by
  rw [compl_eq_univ_diff]
  exact measure_diff (subset_univ s) h₁ h_fin
#align measure_theory.measure_compl MeasureTheory.measure_compl

@[simp]
theorem union_ae_eq_left_iff_ae_subset : (s ∪ t : Set α) =ᵐ[μ] s ↔ t ≤ᵐ[μ] s := by
  rw [ae_le_set]
  refine'
    ⟨fun h => by simpa only [union_diff_left] using (ae_eq_set.mp h).1, fun h =>
      eventuallyLE_antisymm_iff.mpr
        ⟨by rwa [ae_le_set, union_diff_left],
          HasSubset.Subset.eventuallyLE <| subset_union_left s t⟩⟩
#align measure_theory.union_ae_eq_left_iff_ae_subset MeasureTheory.union_ae_eq_left_iff_ae_subset

@[simp]
theorem union_ae_eq_right_iff_ae_subset : (s ∪ t : Set α) =ᵐ[μ] t ↔ s ≤ᵐ[μ] t := by
  rw [union_comm, union_ae_eq_left_iff_ae_subset]
#align measure_theory.union_ae_eq_right_iff_ae_subset MeasureTheory.union_ae_eq_right_iff_ae_subset

theorem ae_eq_of_ae_subset_of_measure_ge (h₁ : s ≤ᵐ[μ] t) (h₂ : μ t ≤ μ s) (hsm : MeasurableSet s)
    (ht : μ t ≠ ∞) : s =ᵐ[μ] t := by
  refine' eventuallyLE_antisymm_iff.mpr ⟨h₁, ae_le_set.mpr _⟩
  replace h₂ : μ t = μ s; exact h₂.antisymm (measure_mono_ae h₁)
  replace ht : μ s ≠ ∞; exact h₂ ▸ ht
  rw [measure_diff' t hsm ht, measure_congr (union_ae_eq_left_iff_ae_subset.mpr h₁), h₂, tsub_self]
#align measure_theory.ae_eq_of_ae_subset_of_measure_ge MeasureTheory.ae_eq_of_ae_subset_of_measure_ge

/-- If `s ⊆ t`, `μ t ≤ μ s`, `μ t ≠ ∞`, and `s` is measurable, then `s =ᵐ[μ] t`. -/
theorem ae_eq_of_subset_of_measure_ge (h₁ : s ⊆ t) (h₂ : μ t ≤ μ s) (hsm : MeasurableSet s)
    (ht : μ t ≠ ∞) : s =ᵐ[μ] t :=
  ae_eq_of_ae_subset_of_measure_ge (HasSubset.Subset.eventuallyLE h₁) h₂ hsm ht
#align measure_theory.ae_eq_of_subset_of_measure_ge MeasureTheory.ae_eq_of_subset_of_measure_ge

theorem measure_unionᵢ_congr_of_subset [Countable β] {s : β → Set α} {t : β → Set α}
    (hsub : ∀ b, s b ⊆ t b) (h_le : ∀ b, μ (t b) ≤ μ (s b)) : μ (⋃ b, s b) = μ (⋃ b, t b) := by
  rcases em (∃ b, μ (t b) = ∞) with (⟨b, hb⟩ | htop)
  ·
    calc
      μ (⋃ b, s b) = ∞ := top_unique (hb ▸ (h_le b).trans <| measure_mono <| subset_unionᵢ _ _)
      _ = μ (⋃ b, t b) := Eq.symm <| top_unique <| hb ▸ measure_mono <| subset_unionᵢ _ _

  push_neg  at htop
  refine' le_antisymm (measure_mono (unionᵢ_mono hsub)) _
  set M := toMeasurable μ
  have H : ∀ b, (M (t b) ∩ M (⋃ b, s b) : Set α) =ᵐ[μ] M (t b) := by
    refine' fun b => ae_eq_of_subset_of_measure_ge (inter_subset_left _ _) _ _ _
    ·
      calc
        μ (M (t b)) = μ (t b) := measure_toMeasurable _
        _ ≤ μ (s b) := (h_le b)
        _ ≤ μ (M (t b) ∩ M (⋃ b, s b)) :=
          measure_mono <|
            subset_inter ((hsub b).trans <| subset_toMeasurable _ _)
              ((subset_unionᵢ _ _).trans <| subset_toMeasurable _ _)

    · exact (measurable_set_toMeasurable _ _).inter (measurable_set_toMeasurable _ _)
    · rw [measure_toMeasurable]
      exact htop b
  calc
    μ (⋃ b, t b) ≤ μ (⋃ b, M (t b)) := measure_mono (unionᵢ_mono fun b => subset_toMeasurable _ _)
    _ = μ (⋃ b, M (t b) ∩ M (⋃ b, s b)) := (measure_congr (EventuallyEq.countable_unionᵢ H).symm)
    _ ≤ μ (M (⋃ b, s b)) := (measure_mono (unionᵢ_subset fun b => inter_subset_right _ _))
    _ = μ (⋃ b, s b) := measure_toMeasurable _

#align measure_theory.measure_Union_congr_of_subset MeasureTheory.measure_unionᵢ_congr_of_subset

theorem measure_union_congr_of_subset {t₁ t₂ : Set α} (hs : s₁ ⊆ s₂) (hsμ : μ s₂ ≤ μ s₁)
    (ht : t₁ ⊆ t₂) (htμ : μ t₂ ≤ μ t₁) : μ (s₁ ∪ t₁) = μ (s₂ ∪ t₂) := by
  rw [union_eq_unionᵢ, union_eq_unionᵢ]
  exact measure_unionᵢ_congr_of_subset (Bool.forall_bool.2 ⟨ht, hs⟩) (Bool.forall_bool.2 ⟨htμ, hsμ⟩)
#align measure_theory.measure_union_congr_of_subset MeasureTheory.measure_union_congr_of_subset

@[simp]
theorem measure_unionᵢ_toMeasurable [Countable β] (s : β → Set α) :
    μ (⋃ b, toMeasurable μ (s b)) = μ (⋃ b, s b) :=
  Eq.symm <|
    measure_unionᵢ_congr_of_subset (fun b => subset_toMeasurable _ _) fun b =>
      (measure_toMeasurable _).le
#align measure_theory.measure_Union_to_measurable MeasureTheory.measure_unionᵢ_toMeasurable

theorem measure_bunionᵢ_toMeasurable {I : Set β} (hc : I.Countable) (s : β → Set α) :
    μ (⋃ b ∈ I, toMeasurable μ (s b)) = μ (⋃ b ∈ I, s b) := by
  haveI := hc.toEncodable
  simp only [bunionᵢ_eq_unionᵢ, measure_unionᵢ_toMeasurable]
#align measure_theory.measure_bUnion_to_measurable MeasureTheory.measure_bunionᵢ_toMeasurable

@[simp]
theorem measure_toMeasurable_union : μ (toMeasurable μ s ∪ t) = μ (s ∪ t) :=
  Eq.symm <|
    measure_union_congr_of_subset (subset_toMeasurable _ _) (measure_toMeasurable _).le Subset.rfl
      le_rfl
#align measure_theory.measure_to_measurable_union MeasureTheory.measure_toMeasurable_union

@[simp]
theorem measure_union_toMeasurable : μ (s ∪ toMeasurable μ t) = μ (s ∪ t) :=
  Eq.symm <|
    measure_union_congr_of_subset Subset.rfl le_rfl (subset_toMeasurable _ _)
      (measure_toMeasurable _).le
#align measure_theory.measure_union_to_measurable MeasureTheory.measure_union_toMeasurable

theorem sum_measure_le_measure_univ {s : Finset ι} {t : ι → Set α}
    (h : ∀ i ∈ s, MeasurableSet (t i)) (H : Set.PairwiseDisjoint (↑s) t) :
    (∑ i in s, μ (t i)) ≤ μ (univ : Set α) := by
  rw [← measure_bunionᵢ_finset H h]
  exact measure_mono (subset_univ _)
#align measure_theory.sum_measure_le_measure_univ MeasureTheory.sum_measure_le_measure_univ

theorem tsum_measure_le_measure_univ {s : ι → Set α} (hs : ∀ i, MeasurableSet (s i))
    (H : Pairwise (Disjoint on s)) : (∑' i, μ (s i)) ≤ μ (univ : Set α) := by
  rw [ENNReal.tsum_eq_supᵢ_sum]
  exact supᵢ_le fun s => sum_measure_le_measure_univ (fun i hi => hs i) fun i hi j hj hij => H hij
#align measure_theory.tsum_measure_le_measure_univ MeasureTheory.tsum_measure_le_measure_univ

/-- Pigeonhole principle for measure spaces: if `∑' i, μ (s i) > μ univ`, then
one of the intersections `s i ∩ s j` is not empty. -/
theorem exists_nonempty_inter_of_measure_univ_lt_tsum_measure {m : MeasurableSpace α}
    (μ : Measure α) {s : ι → Set α} (hs : ∀ i, MeasurableSet (s i))
    (H : μ (univ : Set α) < ∑' i, μ (s i)) : ∃ (i j : _)(h : i ≠ j), (s i ∩ s j).Nonempty := by
  contrapose! H
  apply tsum_measure_le_measure_univ hs
  intro i j hij
  rw [Function.onFun, disjoint_iff_inf_le]
  exact fun x hx => H i j hij ⟨x, hx⟩
#align measure_theory.exists_nonempty_inter_of_measure_univ_lt_tsum_measure MeasureTheory.exists_nonempty_inter_of_measure_univ_lt_tsum_measure

/-- Pigeonhole principle for measure spaces: if `s` is a `finset` and
`∑ i in s, μ (t i) > μ univ`, then one of the intersections `t i ∩ t j` is not empty. -/
theorem exists_nonempty_inter_of_measure_univ_lt_sum_measure {m : MeasurableSpace α} (μ : Measure α)
    {s : Finset ι} {t : ι → Set α} (h : ∀ i ∈ s, MeasurableSet (t i))
    (H : μ (univ : Set α) < ∑ i in s, μ (t i)) :
    ∃ i ∈ s, ∃ j ∈ s, ∃ h : i ≠ j, (t i ∩ t j).Nonempty := by
  contrapose! H
  apply sum_measure_le_measure_univ h
  intro i hi j hj hij
  rw [Function.onFun, disjoint_iff_inf_le]
  exact fun x hx => H i hi j hj hij ⟨x, hx⟩
#align measure_theory.exists_nonempty_inter_of_measure_univ_lt_sum_measure MeasureTheory.exists_nonempty_inter_of_measure_univ_lt_sum_measure

/-- If two sets `s` and `t` are included in a set `u`, and `μ s + μ t > μ u`,
then `s` intersects `t`. Version assuming that `t` is measurable. -/
theorem nonempty_inter_of_measure_lt_add {m : MeasurableSpace α} (μ : Measure α) {s t u : Set α}
    (ht : MeasurableSet t) (h's : s ⊆ u) (h't : t ⊆ u) (h : μ u < μ s + μ t) : (s ∩ t).Nonempty :=
  by
  rw [← Set.not_disjoint_iff_nonempty_inter]
  contrapose! h
  calc
    μ s + μ t = μ (s ∪ t) := (measure_union h ht).symm
    _ ≤ μ u := measure_mono (union_subset h's h't)

#align measure_theory.nonempty_inter_of_measure_lt_add MeasureTheory.nonempty_inter_of_measure_lt_add

/-- If two sets `s` and `t` are included in a set `u`, and `μ s + μ t > μ u`,
then `s` intersects `t`. Version assuming that `s` is measurable. -/
theorem nonempty_inter_of_measure_lt_add' {m : MeasurableSpace α} (μ : Measure α) {s t u : Set α}
    (hs : MeasurableSet s) (h's : s ⊆ u) (h't : t ⊆ u) (h : μ u < μ s + μ t) : (s ∩ t).Nonempty :=
  by
  rw [add_comm] at h
  rw [inter_comm]
  exact nonempty_inter_of_measure_lt_add μ hs h't h's h
#align measure_theory.nonempty_inter_of_measure_lt_add' MeasureTheory.nonempty_inter_of_measure_lt_add'

/-- Continuity from below: the measure of the union of a directed sequence of (not necessarily
-measurable) sets is the supremum of the measures. -/
theorem measure_unionᵢ_eq_supᵢ [Countable ι] {s : ι → Set α} (hd : Directed (· ⊆ ·) s) :
    μ (⋃ i, s i) = ⨆ i, μ (s i) := by
  cases nonempty_encodable ι
  -- WLOG, `ι = ℕ`
  generalize ht : Function.extend Encodable.encode s ⊥ = t
  replace hd : Directed (· ⊆ ·) t := ht ▸ hd.extend_bot Encodable.encode_injective
  suffices μ (⋃ n, t n) = ⨆ n, μ (t n) by
    simp only [← ht, Encodable.encode_injective.apply_extend μ, ← supᵢ_eq_unionᵢ,
      supᵢ_extend_bot Encodable.encode_injective, (· ∘ ·), Pi.bot_apply, bot_eq_empty,
      measure_empty] at this
    exact this.trans (supᵢ_extend_bot Encodable.encode_injective _)
  clear! ι
  -- The `≥` inequality is trivial
  refine' le_antisymm _ (supᵢ_le fun i => measure_mono <| subset_unionᵢ _ _)
  -- Choose `T n ⊇ t n` of the same measure, put `Td n = disjointed T`
  set T : ℕ → Set α := fun n => toMeasurable μ (t n)
  set Td : ℕ → Set α := disjointed T
  have hm : ∀ n, MeasurableSet (Td n) :=
    MeasurableSet.disjointed fun n => measurableSet_toMeasurable _ _
  calc
    μ (⋃ n, t n) ≤ μ (⋃ n, T n) := measure_mono (unionᵢ_mono fun i => subset_toMeasurable _ _)
    _ = μ (⋃ n, Td n) := by rw [unionᵢ_disjointed]
    _ ≤ ∑' n, μ (Td n) := (measure_unionᵢ_le _)
    _ = ⨆ I : Finset ℕ, ∑ n in I, μ (Td n) := ENNReal.tsum_eq_supᵢ_sum
    _ ≤ ⨆ n, μ (t n) := supᵢ_le fun I => _

  rcases hd.finset_le I with ⟨N, hN⟩
  calc
    (∑ n in I, μ (Td n)) = μ (⋃ n ∈ I, Td n) :=
      (measure_bunionᵢ_finset ((disjoint_disjointed T).set_pairwise I) fun n _ => hm n).symm
    _ ≤ μ (⋃ n ∈ I, T n) := (measure_mono (unionᵢ₂_mono fun n hn => disjointed_subset _ _))
    _ = μ (⋃ n ∈ I, t n) := (measure_bunionᵢ_toMeasurable I.countable_to_set _)
    _ ≤ μ (t N) := (measure_mono (unionᵢ₂_subset hN))
    _ ≤ ⨆ n, μ (t n) := le_supᵢ (μ ∘ t) N

#align measure_theory.measure_Union_eq_supr MeasureTheory.measure_unionᵢ_eq_supᵢ

theorem measure_bunionᵢ_eq_supᵢ {s : ι → Set α} {t : Set ι} (ht : t.Countable)
    (hd : DirectedOn ((· ⊆ ·) on s) t) : μ (⋃ i ∈ t, s i) = ⨆ i ∈ t, μ (s i) := by
  haveI := ht.toEncodable
  rw [bunionᵢ_eq_unionᵢ, measure_unionᵢ_eq_supᵢ hd.directed_coe, ← supᵢ_subtype'']
#align measure_theory.measure_bUnion_eq_supr MeasureTheory.measure_bunionᵢ_eq_supᵢ

/- ./././Mathport/Syntax/Translate/Basic.lean:635:2: warning: expanding binder collection (t «expr ⊆ » s k) -/
/-- Continuity from above: the measure of the intersection of a decreasing sequence of measurable
sets is the infimum of the measures. -/
theorem measure_interᵢ_eq_infᵢ [Countable ι] {s : ι → Set α} (h : ∀ i, MeasurableSet (s i))
    (hd : Directed (· ⊇ ·) s) (hfin : ∃ i, μ (s i) ≠ ∞) : μ (⋂ i, s i) = ⨅ i, μ (s i) := by
  rcases hfin with ⟨k, hk⟩
  have : ∀ (t) (_ : t ⊆ s k), μ t ≠ ∞ := fun t ht => ne_top_of_le_ne_top hk (measure_mono ht)
  rw [← ENNReal.sub_sub_cancel hk (infᵢ_le _ k), ENNReal.sub_infᵢ, ←
    ENNReal.sub_sub_cancel hk (measure_mono (interᵢ_subset _ k)), ←
    measure_diff (interᵢ_subset _ k) (MeasurableSet.interᵢ h) (this _ (interᵢ_subset _ k)),
    diff_interᵢ, measure_unionᵢ_eq_supᵢ]
  · congr 1
    refine' le_antisymm (supᵢ_mono' fun i => _) (supᵢ_mono fun i => _)
    · rcases hd i k with ⟨j, hji, hjk⟩
      use j
      rw [← measure_diff hjk (h _) (this _ hjk)]
      exact measure_mono (diff_subset_diff_right hji)
    · rw [tsub_le_iff_right, ← measure_union disjoint_sdiff_left (h i), Set.union_comm]
      exact measure_mono (diff_subset_iff.1 <| subset.refl _)
  · exact hd.mono_comp _ fun _ _ => diff_subset_diff_right
#align measure_theory.measure_Inter_eq_infi MeasureTheory.measure_interᵢ_eq_infᵢ

/-- Continuity from below: the measure of the union of an increasing sequence of measurable sets
is the limit of the measures. -/
theorem tendsto_measure_unionᵢ [SemilatticeSup ι] [Countable ι] {s : ι → Set α} (hm : Monotone s) :
    Tendsto (μ ∘ s) atTop (𝓝 (μ (⋃ n, s n))) := by
  rw [measure_unionᵢ_eq_supᵢ (directed_of_sup hm)]
  exact tendsto_atTop_supᵢ fun n m hnm => measure_mono <| hm hnm
#align measure_theory.tendsto_measure_Union MeasureTheory.tendsto_measure_unionᵢ

/-- Continuity from above: the measure of the intersection of a decreasing sequence of measurable
sets is the limit of the measures. -/
theorem tendsto_measure_interᵢ [Countable ι] [SemilatticeSup ι] {s : ι → Set α}
    (hs : ∀ n, MeasurableSet (s n)) (hm : Antitone s) (hf : ∃ i, μ (s i) ≠ ∞) :
    Tendsto (μ ∘ s) atTop (𝓝 (μ (⋂ n, s n))) := by
  rw [measure_interᵢ_eq_infᵢ hs (directed_of_sup hm) hf]
  exact tendsto_atTop_infᵢ fun n m hnm => measure_mono <| hm hnm
#align measure_theory.tendsto_measure_Inter MeasureTheory.tendsto_measure_interᵢ

/-- The measure of the intersection of a decreasing sequence of measurable
sets indexed by a linear order with first countable topology is the limit of the measures. -/
theorem tendsto_measure_binterᵢ_gt {ι : Type _} [LinearOrder ι] [TopologicalSpace ι]
    [OrderTopology ι] [DenselyOrdered ι] [TopologicalSpace.FirstCountableTopology ι] {s : ι → Set α}
    {a : ι} (hs : ∀ r > a, MeasurableSet (s r)) (hm : ∀ i j, a < i → i ≤ j → s i ⊆ s j)
    (hf : ∃ r > a, μ (s r) ≠ ∞) : Tendsto (μ ∘ s) (𝓝[Ioi a] a) (𝓝 (μ (⋂ r > a, s r))) := by
  refine' tendsto_order.2 ⟨fun l hl => _, fun L hL => _⟩
  ·
    filter_upwards [self_mem_nhdsWithin] with r hr using hl.trans_le
        (measure_mono (binterᵢ_subset_of_mem hr))
  obtain ⟨u, u_anti, u_pos, u_lim⟩ :
    ∃ u : ℕ → ι, StrictAnti u ∧ (∀ n : ℕ, a < u n) ∧ Tendsto u atTop (𝓝 a) := by
    rcases hf with ⟨r, ar, hr⟩
    rcases exists_seq_strictAnti_tendsto' ar with ⟨w, w_anti, w_mem, w_lim⟩
    exact ⟨w, w_anti, fun n => (w_mem n).1, w_lim⟩
  have A : Tendsto (μ ∘ s ∘ u) atTop (𝓝 (μ (⋂ n, s (u n)))) := by
    refine' tendsto_measure_interᵢ (fun n => hs _ (u_pos n)) _ _
    · intro m n hmn
      exact hm _ _ (u_pos n) (u_anti.antitone hmn)
    · rcases hf with ⟨r, rpos, hr⟩
      obtain ⟨n, hn⟩ : ∃ n : ℕ, u n < r := ((tendsto_order.1 u_lim).2 r rpos).exists
      refine' ⟨n, ne_of_lt (lt_of_le_of_lt _ hr.lt_top)⟩
      exact measure_mono (hm _ _ (u_pos n) hn.le)
  have B : (⋂ n, s (u n)) = ⋂ r > a, s r := by
    apply Subset.antisymm
    · simp only [subset_interᵢ_iff, gt_iff_lt]
      intro r rpos
      obtain ⟨n, hn⟩ : ∃ n, u n < r := ((tendsto_order.1 u_lim).2 _ rpos).exists
      exact Subset.trans (interᵢ_subset _ n) (hm (u n) r (u_pos n) hn.le)
    · simp only [subset_interᵢ_iff, gt_iff_lt]
      intro n
      apply binterᵢ_subset_of_mem
      exact u_pos n
  rw [B] at A
  obtain ⟨n, hn⟩ : ∃ n, μ (s (u n)) < L := ((tendsto_order.1 A).2 _ hL).exists
  have : Ioc a (u n) ∈ 𝓝[>] a := Ioc_mem_nhdsWithin_Ioi ⟨le_rfl, u_pos n⟩
  filter_upwards [this]with r hr using lt_of_le_of_lt (measure_mono (hm _ _ hr.1 hr.2)) hn
#align measure_theory.tendsto_measure_bInter_gt MeasureTheory.tendsto_measure_binterᵢ_gt

/-- One direction of the **Borel-Cantelli lemma**: if (sᵢ) is a sequence of sets such
that `∑ μ sᵢ` is finite, then the limit superior of the `sᵢ` is a null set. -/
theorem measure_limsup_eq_zero {s : ℕ → Set α} (hs : (∑' i, μ (s i)) ≠ ∞) :
    μ (limsup s atTop) = 0 := by
  -- First we replace the sequence `sₙ` with a sequence of measurable sets `tₙ ⊇ sₙ` of the same
  -- measure.
  set t : ℕ → Set α := fun n => toMeasurable μ (s n)
  have ht : (∑' i, μ (t i)) ≠ ∞ := by simpa only [measure_toMeasurable] using hs
  suffices μ (limsup t atTop) = 0 by
    have A : s ≤ t := fun n => subset_toMeasurable μ (s n)
    -- TODO default args fail
    exact
      measure_mono_null
        (limsup_le_limsup (eventually_of_forall (Pi.le_def.mp A)) isCobounded_le_of_bot
          isBounded_le_of_top)
        this
  -- Next we unfold `limsup` for sets and replace equality with an inequality
  simp only [limsup_eq_infᵢ_supᵢ_of_nat', Set.infᵢ_eq_interᵢ, Set.supᵢ_eq_unionᵢ, ←
    nonpos_iff_eq_zero]
  -- Finally, we estimate `μ (⋃ i, t (i + n))` by `∑ i', μ (t (i + n))`
  refine'
    le_of_tendsto_of_tendsto'
      (tendsto_measure_interᵢ
        (fun i => MeasurableSet.unionᵢ fun b => measurableSet_toMeasurable _ _) _
        ⟨0, ne_top_of_le_ne_top ht (measure_unionᵢ_le t)⟩)
      (ENNReal.tendsto_sum_nat_add (μ ∘ t) ht) fun n => measure_unionᵢ_le _
  intro n m hnm x
  simp only [Set.mem_unionᵢ]
  exact fun ⟨i, hi⟩ => ⟨i + (m - n), by simpa only [add_assoc, tsub_add_cancel_of_le hnm] using hi⟩
#align measure_theory.measure_limsup_eq_zero MeasureTheory.measure_limsup_eq_zero

/- ./././Mathport/Syntax/Translate/Tactic/Builtin.lean:69:18: unsupported non-interactive tactic filter.is_bounded_default -/
/- ./././Mathport/Syntax/Translate/Tactic/Builtin.lean:69:18: unsupported non-interactive tactic filter.is_bounded_default -/
theorem measure_liminf_eq_zero {s : ℕ → Set α} (h : (∑' i, μ (s i)) ≠ ⊤) : μ (liminf s atTop) = 0 :=
  by
  rw [← le_zero_iff]
  have : liminf s atTop ≤ limsup s atTop :=
    liminf_le_limsup
      (by isBoundedDefault)
      (by isBoundedDefault)
  exact (μ.mono this).trans (by simp [measure_limsup_eq_zero h])
#align measure_theory.measure_liminf_eq_zero MeasureTheory.measure_liminf_eq_zero

theorem limsup_ae_eq_of_forall_ae_eq (s : ℕ → Set α) {t : Set α}
    (h : ∀ n, s n =ᵐ[μ] t) :-- Need `@` below because of diamond; see gh issue #16932
        @limsup
        (Set α) ℕ _ s atTop =ᵐ[μ]
      t := by
  simp_rw [ae_eq_set] at h⊢
  constructor
  · rw [atTop.limsup_sdiff s t]
    apply measure_limsup_eq_zero
    simp [h]
  · rw [atTop.sdiff_limsup s t]
    apply measure_liminf_eq_zero
    simp [h]
#align measure_theory.limsup_ae_eq_of_forall_ae_eq MeasureTheory.limsup_ae_eq_of_forall_ae_eq

theorem liminf_ae_eq_of_forall_ae_eq (s : ℕ → Set α) {t : Set α}
    (h : ∀ n, s n =ᵐ[μ] t) :-- Need `@` below because of diamond; see gh issue #16932
        @liminf
        (Set α) ℕ _ s atTop =ᵐ[μ]
      t := by
  simp_rw [ae_eq_set] at h⊢
  constructor
  · rw [atTop.liminf_sdiff s t]
    apply measure_liminf_eq_zero
    simp [h]
  · rw [atTop.sdiff_liminf s t]
    apply measure_limsup_eq_zero
    simp [h]
#align measure_theory.liminf_ae_eq_of_forall_ae_eq MeasureTheory.liminf_ae_eq_of_forall_ae_eq

theorem measure_if {x : β} {t : Set β} {s : Set α} :
    μ (if x ∈ t then s else ∅) = indicator t (fun _ => μ s) x := by split_ifs <;> simp [h]
#align measure_theory.measure_if MeasureTheory.measure_if

end

section OuterMeasure

variable [ms : MeasurableSpace α] {s t : Set α}

include ms

/-- Obtain a measure by giving an outer measure where all sets in the σ-algebra are
  Carathéodory measurable. -/
def OuterMeasure.toMeasure (m : OuterMeasure α) (h : ms ≤ m.caratheodory) : Measure α :=
  Measure.ofMeasurable (fun s _ => m s) m.Empty fun f hf hd =>
    m.unionᵢ_eq_of_caratheodory (fun i => h _ (hf i)) hd
#align measure_theory.outer_measure.to_measure MeasureTheory.OuterMeasure.toMeasure

theorem le_toOuterMeasure_caratheodory (μ : Measure α) : ms ≤ μ.toOuterMeasure.caratheodory :=
  fun s hs t => (measure_inter_add_diff _ hs).symm
#align measure_theory.le_to_outer_measure_caratheodory MeasureTheory.le_toOuterMeasure_caratheodory

@[simp]
theorem toMeasure_toOuterMeasure (m : OuterMeasure α) (h : ms ≤ m.caratheodory) :
    (m.toMeasure h).toOuterMeasure = m.trim :=
  rfl
#align measure_theory.to_measure_to_outer_measure MeasureTheory.toMeasure_toOuterMeasure

@[simp]
theorem toMeasure_apply (m : OuterMeasure α) (h : ms ≤ m.caratheodory) {s : Set α}
    (hs : MeasurableSet s) : m.toMeasure h s = m s :=
  m.trim_eq hs
#align measure_theory.to_measure_apply MeasureTheory.toMeasure_apply

theorem le_toMeasure_apply (m : OuterMeasure α) (h : ms ≤ m.caratheodory) (s : Set α) :
    m s ≤ m.toMeasure h s :=
  m.le_trim s
#align measure_theory.le_to_measure_apply MeasureTheory.le_toMeasure_apply

theorem toMeasure_apply₀ (m : OuterMeasure α) (h : ms ≤ m.caratheodory) {s : Set α}
    (hs : NullMeasurableSet s (m.toMeasure h)) : m.toMeasure h s = m s := by
  refine' le_antisymm _ (le_to_measure_apply _ _ _)
  rcases hs.exists_measurable_subset_ae_eq with ⟨t, hts, htm, heq⟩
  calc
    m.to_measure h s = m.to_measure h t := measure_congr HEq.symm
    _ = m t := (to_measure_apply m h htm)
    _ ≤ m s := m.mono hts

#align measure_theory.to_measure_apply₀ MeasureTheory.toMeasure_apply₀

@[simp]
theorem toOuterMeasure_toMeasure {μ : Measure α} :
    μ.toOuterMeasure.toMeasure (le_toOuterMeasure_caratheodory _) = μ :=
  Measure.ext fun s => μ.toOuterMeasure.trim_eq
#align measure_theory.to_outer_measure_to_measure MeasureTheory.toOuterMeasure_toMeasure

@[simp]
theorem boundedBy_measure (μ : Measure α) : OuterMeasure.boundedBy μ = μ.toOuterMeasure :=
  μ.toOuterMeasure.boundedBy_eq_self
#align measure_theory.bounded_by_measure MeasureTheory.boundedBy_measure

end OuterMeasure

variable {m0 : MeasurableSpace α} [MeasurableSpace β] [MeasurableSpace γ]

variable {μ μ₁ μ₂ μ₃ ν ν' ν₁ ν₂ : Measure α} {s s' t : Set α}

namespace Measure

/-- If `u` is a superset of `t` with the same (finite) measure (both sets possibly non-measurable),
then for any measurable set `s` one also has `μ (t ∩ s) = μ (u ∩ s)`. -/
theorem measure_inter_eq_of_measure_eq {s t u : Set α} (hs : MeasurableSet s) (h : μ t = μ u)
    (htu : t ⊆ u) (ht_ne_top : μ t ≠ ∞) : μ (t ∩ s) = μ (u ∩ s) := by
  rw [h] at ht_ne_top
  refine' le_antisymm (measure_mono (inter_subset_inter_left _ htu)) _
  have A : μ (u ∩ s) + μ (u \ s) ≤ μ (t ∩ s) + μ (u \ s) :=
    calc
      μ (u ∩ s) + μ (u \ s) = μ u := measure_inter_add_diff _ hs
      _ = μ t := h.symm
      _ = μ (t ∩ s) + μ (t \ s) := (measure_inter_add_diff _ hs).symm
      _ ≤ μ (t ∩ s) + μ (u \ s) :=
        add_le_add le_rfl (measure_mono (diff_subset_diff htu subset.rfl))

  have B : μ (u \ s) ≠ ∞ := (lt_of_le_of_lt (measure_mono (diff_subset _ _)) ht_ne_top.lt_top).Ne
  exact ENNReal.le_of_add_le_add_right B A
#align measure_theory.measure.measure_inter_eq_of_measure_eq MeasureTheory.Measure.measure_inter_eq_of_measure_eq

/-- The measurable superset `to_measurable μ t` of `t` (which has the same measure as `t`)
satisfies, for any measurable set `s`, the equality `μ (to_measurable μ t ∩ s) = μ (u ∩ s)`.
Here, we require that the measure of `t` is finite. The conclusion holds without this assumption
when the measure is sigma_finite, see `measure_to_measurable_inter_of_sigma_finite`. -/
theorem measure_toMeasurable_inter {s t : Set α} (hs : MeasurableSet s) (ht : μ t ≠ ∞) :
    μ (toMeasurable μ t ∩ s) = μ (t ∩ s) :=
  (measure_inter_eq_of_measure_eq hs (measure_toMeasurable t).symm (subset_toMeasurable μ t)
      ht).symm
#align measure_theory.measure.measure_to_measurable_inter MeasureTheory.Measure.measure_toMeasurable_inter

/-! ### The `ℝ≥0∞`-module of measures -/


instance [MeasurableSpace α] : Zero (Measure α) :=
  ⟨{  toOuterMeasure := 0
      m_unionᵢ := fun f hf hd => tsum_zero.symm
      trimmed := OuterMeasure.trim_zero }⟩

@[simp]
theorem zero_toOuterMeasure {m : MeasurableSpace α} : (0 : Measure α).toOuterMeasure = 0 :=
  rfl
#align measure_theory.measure.zero_to_outer_measure MeasureTheory.Measure.zero_toOuterMeasure

@[simp, norm_cast]
theorem coe_zero {m : MeasurableSpace α} : ⇑(0 : Measure α) = 0 :=
  rfl
#align measure_theory.measure.coe_zero MeasureTheory.Measure.coe_zero

instance [IsEmpty α] {m : MeasurableSpace α} : Subsingleton (Measure α) :=
  ⟨fun μ ν => by
    ext1 s hs
    simp only [eq_empty_of_is_empty s, measure_empty]⟩

theorem eq_zero_of_isEmpty [IsEmpty α] {m : MeasurableSpace α} (μ : Measure α) : μ = 0 :=
  Subsingleton.elim μ 0
#align measure_theory.measure.eq_zero_of_is_empty MeasureTheory.Measure.eq_zero_of_isEmpty

instance [MeasurableSpace α] : Inhabited (Measure α) :=
  ⟨0⟩

instance [MeasurableSpace α] : Add (Measure α) :=
  ⟨fun μ₁ μ₂ =>
    { toOuterMeasure := μ₁.toOuterMeasure + μ₂.toOuterMeasure
      m_unionᵢ := fun s hs hd =>
        show μ₁ (⋃ i, s i) + μ₂ (⋃ i, s i) = ∑' i, μ₁ (s i) + μ₂ (s i) by
          rw [ENNReal.tsum_add, measure_Union hd hs, measure_Union hd hs]
      trimmed := by rw [outer_measure.trim_add, μ₁.trimmed, μ₂.trimmed] }⟩

@[simp]
theorem add_toOuterMeasure {m : MeasurableSpace α} (μ₁ μ₂ : Measure α) :
    (μ₁ + μ₂).toOuterMeasure = μ₁.toOuterMeasure + μ₂.toOuterMeasure :=
  rfl
#align measure_theory.measure.add_to_outer_measure MeasureTheory.Measure.add_toOuterMeasure

@[simp, norm_cast]
theorem coe_add {m : MeasurableSpace α} (μ₁ μ₂ : Measure α) : ⇑(μ₁ + μ₂) = μ₁ + μ₂ :=
  rfl
#align measure_theory.measure.coe_add MeasureTheory.Measure.coe_add

theorem add_apply {m : MeasurableSpace α} (μ₁ μ₂ : Measure α) (s : Set α) :
    (μ₁ + μ₂) s = μ₁ s + μ₂ s :=
  rfl
#align measure_theory.measure.add_apply MeasureTheory.Measure.add_apply

section SMul

variable [SMul R ℝ≥0∞] [IsScalarTower R ℝ≥0∞ ℝ≥0∞]

variable [SMul R' ℝ≥0∞] [IsScalarTower R' ℝ≥0∞ ℝ≥0∞]

instance [MeasurableSpace α] : SMul R (Measure α) :=
  ⟨fun c μ =>
    { toOuterMeasure := c • μ.toOuterMeasure
      m_unionᵢ := fun s hs hd => by
        rw [← smul_one_smul ℝ≥0∞ c (_ : outer_measure α)]
        dsimp
        simp_rw [measure_Union hd hs, ENNReal.tsum_mul_left]
      trimmed := by rw [outer_measure.trim_smul, μ.trimmed] }⟩

@[simp]
theorem smul_toOuterMeasure {m : MeasurableSpace α} (c : R) (μ : Measure α) :
    (c • μ).toOuterMeasure = c • μ.toOuterMeasure :=
  rfl
#align measure_theory.measure.smul_to_outer_measure MeasureTheory.Measure.smul_toOuterMeasure

@[simp, norm_cast]
theorem coe_smul {m : MeasurableSpace α} (c : R) (μ : Measure α) : ⇑(c • μ) = c • μ :=
  rfl
#align measure_theory.measure.coe_smul MeasureTheory.Measure.coe_smul

@[simp]
theorem smul_apply {m : MeasurableSpace α} (c : R) (μ : Measure α) (s : Set α) :
    (c • μ) s = c • μ s :=
  rfl
#align measure_theory.measure.smul_apply MeasureTheory.Measure.smul_apply

instance [SMulCommClass R R' ℝ≥0∞] [MeasurableSpace α] : SMulCommClass R R' (Measure α) :=
  ⟨fun _ _ _ => ext fun _ _ => smul_comm _ _ _⟩

instance [SMul R R'] [IsScalarTower R R' ℝ≥0∞] [MeasurableSpace α] :
    IsScalarTower R R' (Measure α) :=
  ⟨fun _ _ _ => ext fun _ _ => smul_assoc _ _ _⟩

instance [SMul Rᵐᵒᵖ ℝ≥0∞] [IsCentralScalar R ℝ≥0∞] [MeasurableSpace α] :
    IsCentralScalar R (Measure α) :=
  ⟨fun _ _ => ext fun _ _ => op_smul_eq_smul _ _⟩

end SMul

instance [Monoid R] [MulAction R ℝ≥0∞] [IsScalarTower R ℝ≥0∞ ℝ≥0∞] [MeasurableSpace α] :
    MulAction R (Measure α) :=
  Injective.mulAction _ toOuterMeasure_injective smul_toOuterMeasure

instance addCommMonoid [MeasurableSpace α] : AddCommMonoid (Measure α) :=
  toOuterMeasure_injective.AddCommMonoid toOuterMeasure zero_toOuterMeasure add_toOuterMeasure
    fun _ _ => smul_toOuterMeasure _ _
#align measure_theory.measure.add_comm_monoid MeasureTheory.Measure.addCommMonoid

/-- Coercion to function as an additive monoid homomorphism. -/
def coeAddHom {m : MeasurableSpace α} : Measure α →+ Set α → ℝ≥0∞ :=
  ⟨coeFn, coe_zero, coe_add⟩
#align measure_theory.measure.coe_add_hom MeasureTheory.Measure.coeAddHom

@[simp]
theorem coe_finset_sum {m : MeasurableSpace α} (I : Finset ι) (μ : ι → Measure α) :
    ⇑(∑ i in I, μ i) = ∑ i in I, μ i :=
  (@coeAddHom α m).map_sum _ _
#align measure_theory.measure.coe_finset_sum MeasureTheory.Measure.coe_finset_sum

theorem finset_sum_apply {m : MeasurableSpace α} (I : Finset ι) (μ : ι → Measure α) (s : Set α) :
    (∑ i in I, μ i) s = ∑ i in I, μ i s := by rw [coe_finset_sum, Finset.sum_apply]
#align measure_theory.measure.finset_sum_apply MeasureTheory.Measure.finset_sum_apply

instance [Monoid R] [DistribMulAction R ℝ≥0∞] [IsScalarTower R ℝ≥0∞ ℝ≥0∞] [MeasurableSpace α] :
    DistribMulAction R (Measure α) :=
  Injective.distribMulAction ⟨toOuterMeasure, zero_toOuterMeasure, add_toOuterMeasure⟩
    toOuterMeasure_injective smul_toOuterMeasure

instance [Semiring R] [Module R ℝ≥0∞] [IsScalarTower R ℝ≥0∞ ℝ≥0∞] [MeasurableSpace α] :
    Module R (Measure α) :=
  Injective.module R ⟨toOuterMeasure, zero_toOuterMeasure, add_toOuterMeasure⟩
    toOuterMeasure_injective smul_toOuterMeasure

@[simp]
theorem coe_nNReal_smul_apply {m : MeasurableSpace α} (c : ℝ≥0) (μ : Measure α) (s : Set α) :
    (c • μ) s = c * μ s :=
  rfl
#align measure_theory.measure.coe_nnreal_smul_apply MeasureTheory.Measure.coe_nNReal_smul_apply

theorem ae_smul_measure_iff {p : α → Prop} {c : ℝ≥0∞} (hc : c ≠ 0) :
    (∀ᵐ x ∂c • μ, p x) ↔ ∀ᵐ x ∂μ, p x := by simp [ae_iff, hc]
#align measure_theory.measure.ae_smul_measure_iff MeasureTheory.Measure.ae_smul_measure_iff

theorem measure_eq_left_of_subset_of_measure_add_eq {s t : Set α} (h : (μ + ν) t ≠ ∞) (h' : s ⊆ t)
    (h'' : (μ + ν) s = (μ + ν) t) : μ s = μ t := by
  refine' le_antisymm (measure_mono h') _
  have : μ t + ν t ≤ μ s + ν t :=
    calc
      μ t + ν t = μ s + ν s := h''.symm
      _ ≤ μ s + ν t := add_le_add le_rfl (measure_mono h')

  apply ENNReal.le_of_add_le_add_right _ this
  simp only [not_or, ENNReal.add_eq_top, Pi.add_apply, Ne.def, coe_add] at h
  exact h.2
#align measure_theory.measure.measure_eq_left_of_subset_of_measure_add_eq MeasureTheory.Measure.measure_eq_left_of_subset_of_measure_add_eq

theorem measure_eq_right_of_subset_of_measure_add_eq {s t : Set α} (h : (μ + ν) t ≠ ∞) (h' : s ⊆ t)
    (h'' : (μ + ν) s = (μ + ν) t) : ν s = ν t := by
  rw [add_comm] at h'' h
  exact measure_eq_left_of_subset_of_measure_add_eq h h' h''
#align measure_theory.measure.measure_eq_right_of_subset_of_measure_add_eq MeasureTheory.Measure.measure_eq_right_of_subset_of_measure_add_eq

theorem measure_toMeasurable_add_inter_left {s t : Set α} (hs : MeasurableSet s)
    (ht : (μ + ν) t ≠ ∞) : μ (toMeasurable (μ + ν) t ∩ s) = μ (t ∩ s) := by
  refine' (measure_inter_eq_of_measure_eq hs _ (subset_to_measurable _ _) _).symm
  · refine'
      measure_eq_left_of_subset_of_measure_add_eq _ (subset_to_measurable _ _)
        (measure_to_measurable t).symm
    rwa [measure_to_measurable t]
  · simp only [not_or, ENNReal.add_eq_top, Pi.add_apply, Ne.def, coe_add] at ht
    exact ht.1
#align measure_theory.measure.measure_to_measurable_add_inter_left MeasureTheory.Measure.measure_toMeasurable_add_inter_left

theorem measure_toMeasurable_add_inter_right {s t : Set α} (hs : MeasurableSet s)
    (ht : (μ + ν) t ≠ ∞) : ν (toMeasurable (μ + ν) t ∩ s) = ν (t ∩ s) := by
  rw [add_comm] at ht⊢
  exact measure_to_measurable_add_inter_left hs ht
#align measure_theory.measure.measure_to_measurable_add_inter_right MeasureTheory.Measure.measure_toMeasurable_add_inter_right

/-! ### The complete lattice of measures -/


/-- Measures are partially ordered.

The definition of less equal here is equivalent to the definition without the
measurable set condition, and this is shown by `measure.le_iff'`. It is defined
this way since, to prove `μ ≤ ν`, we may simply `intros s hs` instead of rewriting followed
by `intros s hs`. -/
instance [MeasurableSpace α] : PartialOrder (Measure α) where
  le m₁ m₂ := ∀ s, MeasurableSet s → m₁ s ≤ m₂ s
  le_refl m s hs := le_rfl
  le_trans m₁ m₂ m₃ h₁ h₂ s hs := le_trans (h₁ s hs) (h₂ s hs)
  le_antisymm m₁ m₂ h₁ h₂ := ext fun s hs => le_antisymm (h₁ s hs) (h₂ s hs)

theorem le_iff : μ₁ ≤ μ₂ ↔ ∀ s, MeasurableSet s → μ₁ s ≤ μ₂ s :=
  Iff.rfl
#align measure_theory.measure.le_iff MeasureTheory.Measure.le_iff

theorem toOuterMeasure_le : μ₁.toOuterMeasure ≤ μ₂.toOuterMeasure ↔ μ₁ ≤ μ₂ := by
  rw [← μ₂.trimmed, outer_measure.le_trim_iff] <;> rfl
#align measure_theory.measure.to_outer_measure_le MeasureTheory.Measure.toOuterMeasure_le

theorem le_iff' : μ₁ ≤ μ₂ ↔ ∀ s, μ₁ s ≤ μ₂ s :=
  toOuterMeasure_le.symm
#align measure_theory.measure.le_iff' MeasureTheory.Measure.le_iff'

theorem lt_iff : μ < ν ↔ μ ≤ ν ∧ ∃ s, MeasurableSet s ∧ μ s < ν s :=
  lt_iff_le_not_le.trans <|
    and_congr Iff.rfl <| by simp only [le_iff, not_forall, not_le, exists_prop]
#align measure_theory.measure.lt_iff MeasureTheory.Measure.lt_iff

theorem lt_iff' : μ < ν ↔ μ ≤ ν ∧ ∃ s, μ s < ν s :=
  lt_iff_le_not_le.trans <| and_congr Iff.rfl <| by simp only [le_iff', not_forall, not_le]
#align measure_theory.measure.lt_iff' MeasureTheory.Measure.lt_iff'

instance covariant_add_le [MeasurableSpace α] :
    CovariantClass (Measure α) (Measure α) (· + ·) (· ≤ ·) :=
  ⟨fun ν μ₁ μ₂ hμ s hs => add_le_add_left (hμ s hs) _⟩
#align measure_theory.measure.covariant_add_le MeasureTheory.Measure.covariant_add_le

protected theorem le_add_left (h : μ ≤ ν) : μ ≤ ν' + ν := fun s hs => le_add_left (h s hs)
#align measure_theory.measure.le_add_left MeasureTheory.Measure.le_add_left

protected theorem le_add_right (h : μ ≤ ν) : μ ≤ ν + ν' := fun s hs => le_add_right (h s hs)
#align measure_theory.measure.le_add_right MeasureTheory.Measure.le_add_right
