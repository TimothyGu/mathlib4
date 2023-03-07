/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Anne Baanen

! This file was ported from Lean 3 source module order.hom.order
! leanprover-community/mathlib commit ba2245edf0c8bb155f1569fd9b9492a9b384cde6
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Logic.Function.Iterate
import Mathlib.Order.GaloisConnection
import Mathlib.Order.Hom.Basic

/-!
# Lattice structure on order homomorphisms

This file defines the lattice structure on order homomorphisms, which are bundled
monotone functions.

## Main definitions

 * `OrderHom.CompleteLattice`: if `β` is a complete lattice, so is `α →o β`

## Tags

monotone map, bundled morphism
-/


namespace OrderHom

variable {α β : Type _}

section Preorder

variable [Preorder α]

instance [SemilatticeSup β] : Sup (α →o β) where
  sup f g := ⟨fun a => f a ⊔ g a, f.mono.sup g.mono⟩

--Porting note: this is the lemma that could have been generated by `@[simps]` on the
--above instance but with a nicer name
@[simp] lemma coe_sup [SemilatticeSup β] (f g : α →o β) :
  ((f ⊔ g : α →o β) : α → β) = (f : α → β) ⊔ g := rfl

instance [SemilatticeSup β] : SemilatticeSup (α →o β) :=
  { (_ : PartialOrder (α →o β)) with
    sup := Sup.sup
    le_sup_left := fun _ _ _ => le_sup_left
    le_sup_right := fun _ _ _ => le_sup_right
    sup_le := fun _ _ _ h₀ h₁ x => sup_le (h₀ x) (h₁ x) }

instance [SemilatticeInf β] : Inf (α →o β) where
  inf f g := ⟨fun a => f a ⊓ g a, f.mono.inf g.mono⟩

--Porting note: this is the lemma that could have been generated by `@[simps]` on the
--above instance but with a nicer name
@[simp] lemma coe_inf [SemilatticeInf β] (f g : α →o β) :
  ((f ⊓ g : α →o β) : α → β) = (f : α → β) ⊓ g := rfl

instance [SemilatticeInf β] : SemilatticeInf (α →o β) :=
  { (_ : PartialOrder (α →o β)), (dualIso α β).symm.toGaloisInsertion.liftSemilatticeInf with
    inf := (· ⊓ ·) }

instance lattice [Lattice β] : Lattice (α →o β) :=
  { (_ : SemilatticeSup (α →o β)), (_ : SemilatticeInf (α →o β)) with }

@[simps]
instance [Preorder β] [OrderBot β] : Bot (α →o β) where
  bot := const α ⊥

instance orderBot [Preorder β] [OrderBot β] : OrderBot (α →o β) where
  bot := ⊥
  bot_le _ _ := bot_le

@[simps]
instance [Preorder β] [OrderTop β] : Top (α →o β) where
  top := const α ⊤

instance orderTop [Preorder β] [OrderTop β] : OrderTop (α →o β) where
  top := ⊤
  le_top _ _ := le_top

instance [CompleteLattice β] : InfSet (α →o β) where
  infₛ s := ⟨fun x => ⨅ f ∈ s, (f : _) x, fun _ _ h => infᵢ₂_mono fun f _ => f.mono h⟩

@[simp]
theorem infₛ_apply [CompleteLattice β] (s : Set (α →o β)) (x : α) :
    infₛ s x = ⨅ f ∈ s, (f : _) x :=
  rfl
#align order_hom.Inf_apply OrderHom.infₛ_apply

theorem infᵢ_apply {ι : Sort _} [CompleteLattice β] (f : ι → α →o β) (x : α) :
    (⨅ i, f i) x = ⨅ i, f i x :=
  (infₛ_apply _ _).trans infᵢ_range
#align order_hom.infi_apply OrderHom.infᵢ_apply

@[simp, norm_cast]
theorem coe_infᵢ {ι : Sort _} [CompleteLattice β] (f : ι → α →o β) :
    ((⨅ i, f i : α →o β) : α → β) = ⨅ i, (f i : α → β) := by
  funext x; simp [infᵢ_apply]
#align order_hom.coe_infi OrderHom.coe_infᵢ

instance [CompleteLattice β] : SupSet (α →o β) where
  supₛ s := ⟨fun x => ⨆ f ∈ s, (f : _) x, fun _ _ h => supᵢ₂_mono fun f _ => f.mono h⟩

@[simp]
theorem supₛ_apply [CompleteLattice β] (s : Set (α →o β)) (x : α) :
    supₛ s x = ⨆ f ∈ s, (f : _) x :=
  rfl
#align order_hom.Sup_apply OrderHom.supₛ_apply

theorem supᵢ_apply {ι : Sort _} [CompleteLattice β] (f : ι → α →o β) (x : α) :
    (⨆ i, f i) x = ⨆ i, f i x :=
  (supₛ_apply _ _).trans supᵢ_range
#align order_hom.supr_apply OrderHom.supᵢ_apply

@[simp, norm_cast]
theorem coe_supᵢ {ι : Sort _} [CompleteLattice β] (f : ι → α →o β) :
    ((⨆ i, f i : α →o β) : α → β) = ⨆ i, (f i : α → β) := by
  funext x; simp [supᵢ_apply]
#align order_hom.coe_supr OrderHom.coe_supᵢ

instance [CompleteLattice β] : CompleteLattice (α →o β) :=
  { (_ : Lattice (α →o β)), OrderHom.orderTop, OrderHom.orderBot with
    -- supₛ := SupSet.supₛ   -- Porting note: removed, unecessary?
    -- Porting note: Added `by apply`, was `fun s f hf x => le_supᵢ_of_le f (le_supᵢ _ hf)`
    le_supₛ := fun s f hf x => le_supᵢ_of_le f (by apply le_supᵢ _ hf)
    supₛ_le := fun s f hf x => supᵢ₂_le fun g hg => hf g hg x
    --inf := infₛ      -- Porting note: removed, unecessary?
    le_infₛ := fun s f hf x => le_infᵢ₂ fun g hg => hf g hg x
    infₛ_le := fun s f hf x => infᵢ_le_of_le f (infᵢ_le _ hf)
    }

theorem iterate_sup_le_sup_iff {α : Type _} [SemilatticeSup α] (f : α →o α) :
    (∀ n₁ n₂ a₁ a₂, (f^[n₁ + n₂]) (a₁ ⊔ a₂) ≤ (f^[n₁]) a₁ ⊔ (f^[n₂]) a₂) ↔
      ∀ a₁ a₂, f (a₁ ⊔ a₂) ≤ f a₁ ⊔ a₂ := by
  constructor <;> intro h
  · exact h 1 0
  · intro n₁ n₂ a₁ a₂
    have h' : ∀ n a₁ a₂, (f^[n]) (a₁ ⊔ a₂) ≤ (f^[n]) a₁ ⊔ a₂ := by
      intro n
      induction' n with n ih <;> intro a₁ a₂
      · rfl
      · calc
          (f^[n + 1]) (a₁ ⊔ a₂) = (f^[n]) (f (a₁ ⊔ a₂)) := Function.iterate_succ_apply f n _
          _ ≤ (f^[n]) (f a₁ ⊔ a₂) := f.mono.iterate n (h a₁ a₂)
          _ ≤ (f^[n]) (f a₁) ⊔ a₂ := ih _ _
          _ = (f^[n + 1]) a₁ ⊔ a₂ := by rw [← Function.iterate_succ_apply]

    calc
      (f^[n₁ + n₂]) (a₁ ⊔ a₂) = (f^[n₁]) ((f^[n₂]) (a₁ ⊔ a₂)) :=
        Function.iterate_add_apply f n₁ n₂ _
      _ = (f^[n₁]) ((f^[n₂]) (a₂ ⊔ a₁)) := by rw [sup_comm]
      _ ≤ (f^[n₁]) ((f^[n₂]) a₂ ⊔ a₁) := f.mono.iterate n₁ (h' n₂ _ _)
      _ = (f^[n₁]) (a₁ ⊔ (f^[n₂]) a₂) := by rw [sup_comm]
      _ ≤ (f^[n₁]) a₁ ⊔ (f^[n₂]) a₂ := h' n₁ a₁ _

#align order_hom.iterate_sup_le_sup_iff OrderHom.iterate_sup_le_sup_iff

end Preorder

end OrderHom
