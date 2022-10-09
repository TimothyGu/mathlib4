/-
Copyright (c) 2020 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Robert Y. Lewis
-/

import Mathlib.Data.RBSet
import Mathlib.Tactic.Linarith.Datatypes

-- TODO finish snake-casing

/-!
# The Fourier-Motzkin elimination procedure

The Fourier-Motzkin procedure is a variable elimination method for linear inequalities.
<https://en.wikipedia.org/wiki/Fourier%E2%80%93Motzkin_elimination>

Given a set of linear inequalities `comps = {tᵢ Rᵢ 0}`,
we aim to eliminate a single variable `a` from the set.
We partition `comps` into `comps_pos`, `comps_neg`, and `comps_zero`,
where `comps_pos` contains the comparisons `tᵢ Rᵢ 0` in which
the coefficient of `a` in `tᵢ` is positive, and similar.

For each pair of comparisons `tᵢ Rᵢ 0 ∈ comps_pos`, `tⱼ Rⱼ 0 ∈ comps_neg`,
we compute coefficients `vᵢ, vⱼ ∈ ℕ` such that `vᵢ*tᵢ + vⱼ*tⱼ` cancels out `a`.
We collect these sums `vᵢ*tᵢ + vⱼ*tⱼ R' 0` in a set `S` and set `comps' = S ∪ comps_zero`,
a new set of comparisons in which `a` has been eliminated.

Theorem: `comps` and `comps'` are equisatisfiable.

We recursively eliminate all variables from the system. If we derive an empty clause `0 < 0`,
we conclude that the original system was unsatisfiable.
-/

open Std

namespace Linarith

/-!
### Datatypes

The `CompSource` and `PComp` datatypes are specific to the FM elimination routine;
they are not shared with other components of `linarith`.
-/

/--
`CompSource` tracks the source of a comparison.
The atomic source of a comparison is an assumption, indexed by a natural number.
Two comparisons can be added to produce a new comparison,
and one comparison can be scaled by a natural number to produce a new comparison.
 -/
-- FIXME @[derive inhabited]
inductive CompSource : Type
| assump : Nat → CompSource
| add : CompSource → CompSource → CompSource
| scale : Nat → CompSource → CompSource

/--
Given a `CompSource` `cs`, `cs.flatten` maps an assumption index
to the number of copies of that assumption that appear in the history of `cs`.

For example, suppose `cs` is produced by scaling assumption 2 by 5,
and adding to that the sum of assumptions 1 and 2.
`cs.flatten` maps `1 ↦ 1, 2 ↦ 6`.
 -/
def CompSource.flatten : CompSource → HashMap Nat Nat
| (CompSource.assump n) => HashMap.empty.insert n 1
| (CompSource.add c1 c2) =>
    (CompSource.flatten c1).mergeWith (fun _ b b' => b + b') (CompSource.flatten c2)
| (CompSource.scale n c) => (CompSource.flatten c).mapVal (fun _ v => v * n)

/-- Formats a `CompSource` for printing. -/
def CompSource.toString : CompSource → String
| (CompSource.assump e) => ToString.toString e
| (CompSource.add c1 c2) => CompSource.toString c1 ++ " + " ++ CompSource.toString c2
| (CompSource.scale n c) => ToString.toString n ++ " * " ++ CompSource.toString c

instance CompSource.ToFormat : ToFormat CompSource :=
  ⟨fun a => CompSource.toString a⟩
#check Ordering
/--
A `PComp` stores a linear comparison `Σ cᵢ*xᵢ R 0`,
along with information about how this comparison was derived.
The original expressions fed into `linarith` are each assigned a unique natural number label.
The *historical set* `PComp.history` stores the labels of expressions
that were used in deriving the current `PComp`.
Variables are also indexed by natural numbers. The sets `PComp.effective`, `PComp.implicit`,
and `PComp.vars` contain variable indices.
* `PComp.vars` contains the variables that appear in `PComp.c`. We store them in `PComp` to
  avoid recomputing the set, which requires folding over a list. (TODO: is this really needed?)
* `PComp.effective` contains the variables that have been effectively eliminated from `PComp`.
  A variable `n` is said to be *effectively eliminated* in `PComp` if the elimination of `n`
  produced at least one of the ancestors of `PComp`.
* `PComp.implicit` contains the variables that have been implicitly eliminated from `PComp`.
  A variable `n` is said to be *implicitly eliminated* in `PComp` if it satisfies the following
  properties:
  - There is some `ancestor` of `PComp` such that `n` appears in `ancestor.vars`.
  - `n` does not appear in `PComp.vars`.
  - `n` was not effectively eliminated.

We track these sets in order to compute whether the history of a `PComp` is *minimal*.
Checking this directly is expensive, but effective approximations can be defined in terms of these
sets. During the variable elimination process, a `PComp` with non-minimal history can be discarded.
-/
structure PComp : Type :=
  (c : Comp)
  (src : CompSource)
  (history : RBSet ℕ Ord.compare)
  (effective : RBSet ℕ Ord.compare)
  (implicit : RBSet ℕ Ord.compare)
  (vars : RBSet ℕ Ord.compare)

/--
Any comparison whose history is not minimal is redundant,
and need not be included in the new set of comparisons.
`elimedGE : ℕ` is a natural number such that all variables with index ≥ `elimedGE` have been
removed from the system.

This test is an overapproximation to minimality. It gives necessary but not sufficient conditions.
If the history of `c` is minimal, then `c.maybeMinimal` is true,
but `c.maybeMinimal` may also be true for some `c` with minimal history.
Thus, if `c.maybeMinimal` is false, `c` is known not to be minimal and must be redundant.
See http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.51.493&rep=rep1&type=pdf p.13
(Theorem 7).
The condition described there considers only implicitly eliminated variables that have been
officially eliminated from the system. This is not the case for every implicitly eliminated
variable. Consider eliminating `z` from `{x + y + z < 0, x - y - z < 0}`. The result is the set
`{2*x < 0}`; `y` is implicitly but not officially eliminated.

This implementation of Fourier-Motzkin elimination processes variables in decreasing order of
indices. Immediately after a step that eliminates variable `k`, variable `k'` has been eliminated
iff `k' ≥ k`. Thus we can compute the intersection of officially and implicitly eliminated variables
by taking the set of implicitly eliminated variables with indices ≥ `elimedGE`.
-/
def PComp.maybeMinimal (c : PComp) (elimedGE : ℕ) : Bool :=
  c.history.size ≤ 1 + ((c.implicit.filter (· ≥ elimedGE)).union c.effective).size

/--
The `src : CompSource` field is ignored when comparing `PComp`s. Two `PComp`s proving the same
comparison, with different sources, are considered equivalent.
-/
def PComp.cmp (p1 p2 : PComp) : Ordering := p1.c.cmp p2.c

/-- `PComp.scale c n` scales the coefficients of `c` by `n` and notes this in the `CompSource`. -/
def PComp.scale (c : PComp) (n : ℕ) : PComp :=
  {c with c := c.c.scale n, src := c.src.scale n}

/--
`PComp.add c1 c2 elimVar` creates the result of summing the linear comparisons `c1` and `c2`,
during the process of eliminating the variable `elimVar`.
The computation assumes, but does not enforce, that `elimVar` appears in both `c1` and `c2`
and does not appear in the sum.
Computing the sum of the two comparisons is easy; the complicated details lie in tracking the
additional fields of `PComp`.
* The historical set `PComp.history` of `c1 + c2` is the union of the two historical sets.
* We recompute the variables that appear in `c1 + c2` from the newly created `Linexp`,
  since some may have been implicitly eliminated.
* The effectively eliminated variables of `c1 + c2` are the union of the two effective sets,
  with `elimVar` inserted.
* The implicitly eliminated variables of `c1 + c2` are those that appear in at least one of
  `c1.vars` and `c2.vars` but not in `(c1 + c2).vars`, excluding `elimVar`.
-/
def PComp.add (c1 c2 : PComp) (elimVar : ℕ) : PComp :=
  let c := c1.c.add c2.c
  let src := c1.src.add c2.src
  let history := c1.history.union c2.history
  let vars := .ofList c.vars _
  let effective := (c1.effective.union c2.effective).insert elimVar
  let implicit := ((c1.vars.union c2.vars).sdiff vars).erase (Ord.compare elimVar)
  ⟨c, src, history, effective, implicit, vars⟩

/--
`PComp.assump c n` creates a `PComp` whose comparison is `c` and whose source is
`CompSource.assump n`, that is, `c` is derived from the `n`th hypothesis.
The history is the singleton set `{n}`.
No variables have been eliminated (effectively or implicitly).
-/
def PComp.assump (c : Comp) (n : ℕ) : PComp :=
{ c := c,
  src := CompSource.assump n,
  history := RBSet.empty.insert n,
  effective := .empty,
  implicit := .empty,
  vars := .ofList c.vars _ }

instance PComp.ToFormat : ToFormat PComp :=
  ⟨fun p => format p.c.coeffs ++ toString p.c.str ++ "0"⟩

abbrev PCompSet := RBSet PComp PComp.cmp

/-! ### Elimination procedure -/

/-- If `c1` and `c2` both contain variable `a` with opposite coefficients,
produces `v1` and `v2` such that `a` has been cancelled in `v1*c1 + v2*c2`. -/
def elimVar (c1 c2 : Comp) (a : ℕ) : Option (ℕ × ℕ) :=
let v1 := c1.coeff_of a
let v2 := c2.coeff_of a
if v1 * v2 < 0 then
  let vlcm :=  Nat.lcm v1.natAbs v2.natAbs
  let  v1' := vlcm / v1.natAbs
  let  v2' := vlcm / v2.natAbs
  some ⟨v1', v2'⟩
else none

/--
`pelimVar p1 p2` calls `elimVar` on the `Comp` components of `p1` and `p2`.
If this returns `v1` and `v2`, it creates a new `PComp` equal to `v1*p1 + v2*p2`,
and tracks this in the `CompSource`.
-/
def pelimVar (p1 p2 : PComp) (a : ℕ) : Option PComp := do
  let (n1, n2) ← elimVar p1.c p2.c a
  return (p1.scale n1).add (p2.scale n2) a

/--
A `PComp` represents a contradiction if its `Comp` field represents a contradiction.
-/
def PComp.isContr (p : PComp) : Bool := p.c.isContr

/--
`elimWithSet a p comps` collects the result of calling `pelimVar p p' a`
for every `p' ∈ comps`.
-/
def elimWithSet (a : ℕ) (p : PComp) (comps : PCompSet) : PCompSet :=
comps.foldl (fun s pc =>
match pelimVar p pc a with
| some pc => if pc.maybeMinimal a then s.insert pc else s
| none => s) RBSet.empty

/--
The state for the elimination monad.
* `maxVar`: the largest variable index that has not been eliminated.
* `comps`: a set of comparisons

The elimination procedure proceeds by eliminating variable `v` from `comps` progressively
in decreasing order.
-/
structure LinarithData : Type :=
  (maxVar : ℕ)
  (comps : PCompSet)

/--
The linarith monad extends an exceptional monad with a `LinarithData` state.
An exception produces a contradictory `PComp`.
-/
-- FIXME derive [Monad, MonadExcept PComp]
@[reducible] def LinarithM : Type → Type :=
StateT LinarithData (ExceptT PComp Id)

instance : Monad LinarithM := inferInstance
instance : MonadExcept PComp LinarithM := inferInstance

/-- Returns the current max variable. -/
def getMaxVar : LinarithM ℕ :=
LinarithData.maxVar <$> get

/-- Return the current comparison set. -/
def getPCompSet : LinarithM PCompSet :=
LinarithData.comps <$> get

/-- Throws an exception if a contradictory `PComp` is contained in the current state. -/
def validate : LinarithM Unit := do
  match (←getPCompSet).toList.find? (fun p : PComp => p.isContr) with
  | none => return ()
  | some c => throw c

/--
Updates the current state with a new max variable and comparisons,
and calls `validate` to check for a contradiction.
-/
def update (maxVar : ℕ) (comps : PCompSet) : LinarithM Unit := do
  StateT.set ⟨maxVar, comps⟩
  validate

/--
`splitSetByVarSign a comps` partitions the set `comps` into three parts.
* `pos` contains the elements of `comps` in which `a` has a positive coefficient.
* `neg` contains the elements of `comps` in which `a` has a negative coefficient.
* `notPresent` contains the elements of `comps` in which `a` has coefficient 0.

Returns `(pos, neg, notPresent)`.
-/
def splitSetByVarSign (a : ℕ) (comps : PCompSet) :
  PCompSet × PCompSet × PCompSet :=
comps.foldl (fun ⟨pos, neg, notPresent⟩ pc =>
  let n := pc.c.coeff_of a
  if n > 0 then ⟨pos.insert pc, neg, notPresent⟩
  else if n < 0 then ⟨pos, neg.insert pc, notPresent⟩
  else ⟨pos, neg, notPresent.insert pc⟩)
  ⟨RBSet.empty, RBSet.empty, RBSet.empty⟩

/--
`elimVarM a` performs one round of Fourier-Motzkin elimination, eliminating the variable `a`
from the `linarith` state.
-/
def elimVarM (a : ℕ) : LinarithM Unit := do
  let vs ← getMaxVar
  if (a ≤ vs) then (do
    let ⟨pos, neg, notPresent⟩ ← splitSetByVarSign a <$> getPCompSet
    let cs' := pos.foldl (fun s p => s.union (elimWithSet a p neg)) notPresent
    update (vs - 1) cs')
  else
    pure ()

/--
`elimAllVarsM` eliminates all variables from the linarith state, leaving it with a set of
ground comparisons. If this succeeds without exception, the original `linarith` state is consistent.
-/
def elimAllVarsM : LinarithM Unit := do
  let mv ← getMaxVar
  for i in (List.range $ mv + 1).reverse do
    elimVarM i

/--
`mkLinarithData hyps vars` takes a list of hypotheses and the largest variable present in
those hypotheses. It produces an initial state for the elimination monad.
-/
def mkLinarithData (hyps : List Comp) (maxVar : ℕ) : LinarithData :=
⟨maxVar, .ofList (hyps.enum.map $ fun ⟨n, cmp⟩ => PComp.assump cmp n) _⟩

/--
`produceCertificate hyps vars` tries to derive a contradiction from the comparisons in `hyps`
by eliminating all variables ≤ `maxVar`.
If successful, it returns a map `coeff : ℕ → ℕ` as a certificate.
This map represents that we can find a contradiction by taking the sum  `∑ (coeff i) * hyps[i]`.
-/
def FourierMotzkin.produceCertificate : CertificateOracle :=
fun hyps maxVar => match ExceptT.run
    (StateT.run (do validate; elimAllVarsM : LinarithM Unit) (mkLinarithData hyps maxVar)) with
| (Except.ok _) => failure
| (Except.error contr) => return contr.src.flatten

end Linarith
