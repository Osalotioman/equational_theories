import Mathlib.Algebra.Lie.OfAssociative
import Mathlib.Analysis.Normed.Field.Lemmas
import Mathlib.Computability.Primrec
import Mathlib.Data.DFinsupp.Encodable
import Mathlib.Data.DFinsupp.FiniteInfinite
import Mathlib.Data.DFinsupp.Multiset
import Mathlib.Data.DFinsupp.Notation
import Mathlib.Data.Int.Star
import Mathlib.GroupTheory.FiniteAbelian.Basic
import Mathlib.LinearAlgebra.Dimension.Localization
import Mathlib.LinearAlgebra.FreeModule.StrongRankCondition
import equational_theories.Equations.Basic
import equational_theories.EquationalResult
import equational_theories.FactsSyntax

-- The ``Obelix law''
-- equation 1491 := x = (y ◇ x) ◇ (y ◇ (y ◇ x))

namespace Obelix
noncomputable section

--The particular group that we'll work on: ℕ-indexed functions to ℚ with finite support.
--To ensure that this is computable (so that we can get the first few elements and verify
--that our non-Astericity), we use DFinsupp, the computable (and dependent) friend of Finsupp.
--The ℕ lets us easily get "fresh" generators to keep extending the function. Finite support means
--that the group is still countable, so we can denumerate every element and eventually add it
--to the domain. We use ℚ so that simply picking anything outside the Module.span of the existing
--elements suffices, because we need guarantees like `3•fresh ≠ a + 2•b`; simply taking elements
--outside the group closure would not suffice for this. #TODO
--Significant amounts of the construction -- even defining the invariants of the partial function --
--depend on this, so we use it explicitly instead of making PartialSolution depend on a group G.
private abbrev A : Type := Π₀ _ : ℕ, ℤ

instance A_module : Module.Free ℤ A := inferInstance

@[ext]
structure PartialSolution where
  --A partial solution is a function f : A → A satisfying certain invariants, with finite domain Dom.
  Dom : Finset A
  f : A → A
  --f is injective on its domain.
  Inj : Dom.toSet.InjOn f
  --f maps the identity to itself
  Dom0 : 0 ∈ Dom
  Id : f 0 = 0
  --If x and f(x) are in the domain, so is f (f x) - f(x).
  Closed_sub : ∀ {a}, a ∈ Dom → f a ∈ Dom → f (f a) - f a ∈ Dom
  --For all x where it's defined, f( f(f(x)) - f(x) ) = x - f(x).
  Valid : ∀ {a}, a ∈ Dom → f a ∈ Dom → f (f (f a) - f a) = a - f a
  --If a and b are in the domain and f(a)-a = f(b)-b, then a=b.
  --Could also be stated as "[fun x ↦ f(x)-x] is injective where defined", hence the name here.
  SubInj : ∀ {a b}, a ∈ Dom → b ∈ Dom → a - f a = b - f b → a = b
  --The extendability criteria: if b is in the image of f as f(a) but not the domain, then
  -- (1) a-b must not be in the domain, and (2) a-b must not be in the range.
  ExtendDom : ∀ {a}, a ∈ Dom → f a ∉ Dom → a - f a ∉ Dom
  ExtendImg : ∀ {a}, a ∈ Dom → f a ∉ Dom → a - f a ∉ f '' Dom

namespace PartialSolution

/-- The image of the partial solution -/
def Im (f : PartialSolution) := f.Dom.image f.f

/-- f.ExtendImg, stated in terms of f.Im -/
theorem ExtendImg' (f : PartialSolution) : ∀ {a}, a ∈ f.Dom → f.f a ∉ f.Dom → a - f.f a ∉ f.Im := by
  intro a h₁ h₂
  convert f.ExtendImg h₁ h₂
  funext x
  simp only [Im, Finset.mem_image, Set.mem_image, Finset.mem_coe]

/-- The group Π₀ : T → ℤ is not finitely generated when T is infinite -/
theorem DFinsuppInfiniteInt_not_FG {T : Type*} [Infinite T] : ¬(AddGroup.FG (Π₀ _ : T, ℤ)) :=
  have h : ¬(AddGroup.FG (Π₀ _ : T, Fin 1064)) := fun _ ↦ DFinsupp.infinite_of_left.not_finite
    <| AddCommGroup.finite_of_fg_torsion (Π₀ _ : T, Fin 1064) (fun _ ↦ by
    rw [isOfFinAddOrder_iff_nsmul_eq_zero]
    exact ⟨1064, by simp, by ext; simp [show (1064:Fin 1064) = 0 by rfl]⟩
  )
  let f : (Π₀ _ : T, ℤ) →+ (Π₀ _ : T, Fin 1064) := DFinsupp.mapRange.addMonoidHom fun _ ↦ Int.castAddHom _
  have : Function.Surjective f := Function.HasRightInverse.surjective
    ⟨DFinsupp.mapRange (fun _ x ↦ x) (by simp), fun _ ↦ by ext; simp [DFinsupp.mapRange, f]⟩
  fun _ ↦ h (AddGroup.fg_of_surjective this)

/-- The module Π₀ _ : ℕ, ℤ is not a finite rank module over ℤ -/
theorem DFinsuppInfinite_not_Finite : ¬(Module.Finite ℤ A) := by
  /- Prove by giving a series of Module equivalences (LinearEquiv's) between DFinsupp,
  Finsupp, and finally Polynomial, where we can appeal to Polynomial.not_finite to do the
  lifting for us. -/
  have f : (Polynomial ℤ) ≃ₗ[ℤ] (Finsupp ℕ ℤ) := {
    toFun := Polynomial.toFinsupp
    invFun := Polynomial.ofFinsupp
    map_add' := by simp
    map_smul' := by
      intros
      rw [zsmul_eq_mul, eq_intCast, Int.cast_id, ← Polynomial.toFinsupp_smul, zsmul_eq_mul]
    left_inv := by simp [Function.LeftInverse]
    right_inv := by simp [Function.RightInverse, Function.LeftInverse]
  }
  rw [← Module.Finite.equiv_iff (finsuppLequivDFinsupp ℤ), ← Module.Finite.equiv_iff f]
  exact Polynomial.not_finite

instance instADenumerable : Denumerable A :=
  Denumerable.ofEncodableOfInfinite A

--This instance lying around keeps on causing diamonds
attribute [-instance] instEncodableDFinsuppOfDecidableNeOfNat

private lemma freshGeneratorExists (f : PartialSolution) (x : A) :
    ∃ y, ∀ (k : ℤ), k ≠ 0 → k • y ∉ Submodule.span ℤ (f.Dom ∪ f.Im ∪ {x} : Set A) := by
  have hRankFin := rank_span_of_finset (R := ℤ) (f.Dom ∪ f.Im ∪ {x} : Finset A)
  rw [Finset.coe_union, Finset.coe_union, Finset.coe_singleton] at hRankFin
  have hRankInfinite : Cardinal.aleph0 ≤ Module.rank ℤ A := by
    by_contra! h
    rw [Module.rank_lt_aleph0_iff] at h
    exact DFinsuppInfinite_not_Finite h
  apply Submodule.exists_smul_notMem_of_rank_lt (R := ℤ)
  exact lt_of_lt_of_le hRankFin hRankInfinite

/-- Get a fresh generator that's not generated by the values in the domain so far, the images
 so far, and a new value x. (If x isn't needed, we can just provide 0.) -/
@[irreducible]
def freshGenerator (f : PartialSolution) (x : A := 0) : A :=
  Classical.choose (freshGeneratorExists f x)

theorem freshGenerator_not_smul_span (f : PartialSolution) (x : A) {k : ℤ} (hk : k ≠ 0) :
    k • f.freshGenerator x ∉ Submodule.span ℤ (f.Dom ∪ f.Im ∪ {x}) := by
  rw [freshGenerator]
  exact Classical.choose_spec (freshGeneratorExists f x) k hk

theorem freshGenerator_not_span (f : PartialSolution) (x : A) :
    f.freshGenerator x ∉ Submodule.span ℤ (f.Dom ∪ f.Im ∪ {x}) := by
  simpa using f.freshGenerator_not_smul_span x (one_ne_zero)

section freshGenerator_lemmas

variable (f : PartialSolution) {x y : A} (a : A := 0)

lemma freshGenerator_not_dom : f.freshGenerator a ∉ f.Dom := by
  have hf := f.freshGenerator_not_span a
  contrapose! hf
  rw [Submodule.mem_span_set']
  use 1, fun _ ↦ 1, fun _ ↦ ⟨f.freshGenerator a, by simp [hf]⟩
  simp

lemma fresh_ne_sum (hx : x ∈ f.Dom) (hy : y ∈ f.Dom) (h i j k l m : ℤ := 0) (hh : h ≠ 0 := by decide):
    h • f.freshGenerator a ≠ i • a + j • x + k • y + l • f.f x + m • f.f y := by
  have hf := f.freshGenerator_not_smul_span a hh
  contrapose! hf
  rw [Submodule.mem_span_set']
  use 5
  use fun n ↦ if n = 0 then i else if n = 1 then j else if n = 2 then k
    else if n = 3 then l else m
  use fun n ↦
    if n = 0 then ⟨a, by simp⟩
    else if n = 1 then ⟨x, by simp [hx]⟩
    else if n = 2 then ⟨y, by simp [hy]⟩
    else if n = 3 then ⟨f.f x, by simp [show f.f x ∈ f.Im by simp [Im]; use x]⟩
    else ⟨f.f y, by simp [show f.f y ∈ f.Im by simp [Im]; use y]⟩
  simp [hf, Fin.sum_univ_def, List.finRange_succ_eq_map]
  abel

lemma fresh_sum_ne_sum (hx : x ∈ f.Dom) (hy : y ∈ f.Dom)
    (h₁ i₁ j₁ k₁ l₁ m₁ h₂ i₂ j₂ k₂ l₂ m₂ : ℤ := 0) (hh : h₁ ≠ h₂ := by decide) :
  h₁ • f.freshGenerator a + i₁ • a + j₁ • x + k₁ • y + l₁ • f.f x + m₁ • f.f y ≠
  h₂ • f.freshGenerator a + i₂ • a + j₂ • x + k₂ • y + l₂ • f.f x + m₂ • f.f y := by
  have hf := (f.fresh_ne_sum a hx hy (h₂ - h₁) (i₁ - i₂) (j₁ - j₂) (k₁ - k₂) (l₁ - l₂) (m₁ - m₂)
    (sub_ne_zero_of_ne hh.symm)).symm
  contrapose! hf
  rw [← neg_add_eq_zero] at hf ⊢
  rw [← hf, ← neg_add_eq_zero]
  simp [sub_smul]
  abel

lemma fresh_ne_f (hx : x ∈ f.Dom) : f.freshGenerator a ≠ f.f x := by
  simpa using f.fresh_ne_sum a hx f.Dom0 1 0 0 0 1

lemma fresh_ne_add_f (hx : x ∈ f.Dom) (hy : y ∈ f.Dom) : f.freshGenerator a ≠ x + f.f y := by
  simpa using f.fresh_ne_sum a hx hy 1 0 1 0 0 1

end freshGenerator_lemmas

/-- Extend a partial solution at an element x in its domain, so that x obeys the functional equation. -/
def extend (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) : PartialSolution :=
  if hb : f.f x ∈ f.Dom then f else
    let b := f.f x;
    let c := f.freshGenerator;
    have hb : b ∉ f.Dom := hb
    have hx₀ : x ≠ 0 := fun h ↦ hb (h ▸ f.Id.symm ▸ f.Dom0 : f.f x ∈ f.Dom)
    have hb₀ : b ≠ 0 := fun h ↦ hb (h ▸ f.Dom0)
    have hbx : b ≠ x := fun h ↦ hb (h ▸ hx)
    have hccb : c ≠ c - b := fun h ↦ hb₀ (sub_eq_self.mp h.symm)
    have hccx : c ≠ c - x := fun h ↦ hx₀ (sub_eq_self.mp h.symm)
    have hxbb : x - b ≠ b :=
      have : ∀ z ∈ f.Dom, f.f z ≠ x - b := by simpa using f.ExtendImg hx hb
      (this x hx).symm
    --All of these are various versions of "the fresh generator is not in the span".
    have hcd : c ∉ f.Dom := f.freshGenerator_not_dom
    have hc₀ : c ≠ 0 := by
      simpa using f.fresh_ne_sum _ f.Dom0 f.Dom0 1
    have hbc : c ≠ b := f.fresh_ne_f _ hx
    have hcx : c ≠ x := fun h ↦ hcd (h ▸ hx)
    have hczd : ∀ z ∈ f.Dom, c - z ∉ f.Dom := fun z hz h ↦
      (show _ ≠ (c - z) + z by simpa +zetaDelta using f.fresh_ne_sum 0 h hz 1 0 1 1)
        (eq_add_of_sub_eq rfl)
    have hfzcx : ∀ z ∈ f.Dom, f.f z ≠ c - x := fun z hz h ↦
      f.fresh_ne_add_f 0 hx hz (add_eq_of_eq_sub' h).symm
    have hczb : ∀ z ∈ f.Dom, c - z ≠ b := fun _ hz h ↦
      (f.fresh_ne_add_f 0 hz hx) (add_comm b _ ▸ eq_add_of_sub_eq h)
    have hbcd : b - c ∉ f.Dom := fun h ↦
      (show b - c ≠ b - c by
        simpa +zetaDelta [add_comm, ← sub_eq_add_neg]
          using f.fresh_sum_ne_sum 0 hx h (-1) 0 0 0 1 0 0 0 0 1) rfl
    have hcbb : c - b ≠ b := by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx f.Dom0 1 0 0 0 (-1) 0 0 0 0 0 1
    have hcbc : c ≠ b - c := by
      simpa [add_comm, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx f.Dom0 1 0 0 0 0 0 (-1) 0 0 0 1
    have hbccb : b - c ≠ c - b := by
      simpa +zetaDelta [add_comm _ b, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx f.Dom0 (-1) 0 0 0 1 0 1 0 0 0 (-1)
    have hzcb : ∀ z ∈ f.Dom, z ≠ c - b := fun _ hz ↦ by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 0 0 0 1 0 0 1 0 0 0 (-1)
    have hbccbxb : b - c ≠ c - b - (x - b) := by
      simpa +zetaDelta [add_comm _ b, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hx (-1) 0 0 0 1 0 1 0 0 (-1)
    have hfzcb : ∀ z ∈ f.Dom, f.f z ≠ c - b := fun z hz ↦ by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 0 0 0 0 0 1 1 0 0 0 (-1)
    have hczfz : ∀ z ∈ f.Dom, c ≠ z - f.f z := fun _ hz ↦ by
      simpa [sub_eq_add_neg] using
        f.fresh_ne_sum _ hz f.Dom0 1 0 1 0 (-1)
    have hfzbc : ∀ z ∈ f.Dom, f.f z ≠ b - c := fun z hz ↦ by
      simpa [add_comm, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 0 0 0 0 0 1 (-1) 0 0 0 1
    have hzbbc : ∀ z ∈ f.Dom, z - b ≠ b - c := fun z hz ↦ by
      simpa +zetaDelta [add_comm _ b, ← sub_eq_add_neg] using
      f.fresh_sum_ne_sum _ hx hz 0 0 0 1 (-1) 0 (-1) 0 0 0 1
    have hzbcz : ∀ z ∈ f.Dom, z - b ≠ c - z := fun z hz ↦ by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 0 0 0 1 (-1) 0 1 0 0 (-1)
    have hzfzcb : ∀ z ∈ f.Dom, z - f.f z ≠ c - b := fun z hz ↦ by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 0 0 0 1 0 (-1) 1 0 0 0 (-1)
    have hcxzfz : ∀ z ∈ f.Dom, c - x ≠ z - f.f z := fun z hz ↦ by
      simpa [← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz 1 0 (-1) 0 0 0 0 0 0 1 0 (-1)
    have hbczfz : ∀ z ∈ f.Dom, b - c ≠ z - f.f z := fun z hz ↦ by
      simpa +zetaDelta [add_comm _ b, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hz (-1) 0 0 0 1 0 0 0 0 1 0 (-1)
    have hffzcb : ∀ z ∈ f.Dom, f.f z ∈ f.Dom → f.f (f.f z) - f.f z ≠ c - b := fun z _ hfz ↦ by
      simpa [add_comm (-f.f z), ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum _ hx hfz 0 0 0 (-1) 0 1 1 0 0 0 (-1)

  {
    Dom := insert b <| insert (c - b) f.Dom
    f := fun y ↦
      if y = b then c
      else if y = c - b then x - b
      else f.f y
    Inj := by
      intro y hy z hz
      simp at hy hz
      rcases hy with hy|hy|hy
      <;> rcases hz with hz|hz|hz
      <;> (try simp only [hy, hz, ↓reduceIte, imp_self, hcbb])
      <;> (try have hyb : y ≠ b := fun h ↦ hb (h ▸ hy); simp [hyb])
      <;> (try have hzb : z ≠ b := fun h ↦ hb (h ▸ hz); simp [hzb])
      <;> (try simp only [hzcb y hy, ↓reduceIte,
        not_false_eq_true, true_implies, imp_false, ne_eq])
      <;> (try simp only [hzcb z hz, ↓reduceIte])
      · exact fun h ↦ (hczfz x hx h).elim
      · exact fun h ↦ (f.fresh_ne_f _ hz h).elim
      · exact (hczfz x hx).symm
      · have := by simpa using f.ExtendImg hx hb
        exact fun h ↦ (this z hz h.symm).elim
      · exact fun h ↦ (f.fresh_ne_f _ hy h.symm).elim
      · have := by simpa using f.ExtendImg hx hb
        exact fun h ↦ (this y hy h).elim
      · exact f.Inj hy hz
    Dom0 := by simp [f.Dom0]
    Id := by simpa [hb₀.symm, (sub_ne_zero_of_ne hbc).symm] using f.Id
    Closed_sub := by
      intro y hy
      simp at hy
      rcases hy with rfl|rfl|hy
      · simp [hbc, hcd, hccb]
      · simpa +zetaDelta [hcbb, f.ExtendDom hx hb, hcx.symm] using (by simp [·])
      · have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hfzcb y hy]
        rintro (hfyb|hfyd)
        · simp [hfyb]
        · have hfyb : f.f y ≠ b := fun h ↦ hb (h ▸ hfyd)
          have hffyb : f.f (f.f y) - f.f y ≠ b := fun h ↦ hb (h ▸ f.Closed_sub hy hfyd)
          simp [hfyb, hfzcb y hy, hffyb, hffzcb y hy hfyd]
          exact f.Closed_sub hy hfyd
    Valid := by
      intro y hy
      simp at hy
      rcases hy with rfl|rfl|hy
      · simp [hbc, hcd, hccb]
      · simp +zetaDelta [hcbb, f.ExtendDom hx hb, hcx.symm, hxbb]
      · have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hfzcb y hy]
        rintro (hfyb|hfyd)
        · simp [hfyb, hcbb]
          exact f.Inj hx hy hfyb.symm
        · have hfyb : f.f y ≠ b := fun h ↦ hb (h ▸ hfyd)
          have hffyb : f.f (f.f y) - f.f y ≠ b := fun h ↦ hb (h ▸ f.Closed_sub hy hfyd)
          simp [hfyb, hfzcb y hy, hffyb, hffzcb y hy hfyd]
          exact f.Valid hy hfyd
    SubInj := by
      intro y z hy hz
      simp at hy hz
      rcases hy with hy|hy|hy
      <;> rcases hz with hz|hz|hz
      <;> (try simp only [hy, hz, ↓reduceIte, imp_self, hcbb])
      <;> (try have hyb : y ≠ b := fun h ↦ hb (h ▸ hy); simp [hyb])
      <;> (try have hzb : z ≠ b := fun h ↦ hb (h ▸ hz); simp [hzb])
      <;> (try simp only [hzcb y hy, ↓reduceIte,
        not_false_eq_true, true_implies, imp_false, ne_eq])
      <;> (try simp only [hzcb z hz, ↓reduceIte])
      · exact fun h ↦ (hbccbxb h).elim
      · exact fun h ↦ (hbczfz z hz h).elim
      · exact hbccbxb.symm
      · exact fun h ↦ (hcxzfz z hz h).elim
      · exact (hbczfz y hy).symm
      · exact (hcxzfz y hy).symm
      · exact f.SubInj hy hz
    ExtendDom := by
      intro y hy
      simp at hy
      rcases hy with rfl|rfl|hy
      · simp [hc₀, hbccb, hbcd]
      · simp [hcbb, hczb x hx, hbx.symm, hczd x hx]
      · have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hzfzcb y hy]
        intro _ _ h3
        constructor
        · intro h
          apply h ▸ f.ExtendImg hy h3
          use x, hx
        · exact f.ExtendDom hy h3
    ExtendImg := by
      intro y hy
      simp at hy
      rcases hy with rfl|rfl|hy
      · simp [hcbc, hcbb, hzbbc x hx]
        intro _ _ _ y hy
        have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hfzbc y hy]
      · simp [hcbb, hccx, hzbcz x hx]
        intro _ _ _ y hy
        have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hfzcx y hy]
      · have hyb : y ≠ b := fun h ↦ hb (h ▸ hy)
        simp [hyb, hzcb y hy, hczfz y hy, hcbb]
        intro hfyb
        have hyx : y ≠ x := fun h ↦ hfyb (congrArg f.f h)
        have hxbyfy : x - b ≠ y - f.f y := fun h ↦ hyx.symm (f.SubInj hx hy h)
        simp [hxbyfy]
        intro _ hy2 z hz
        have hzb : z ≠ b := fun h ↦ hb (h ▸ hz)
        have := by simpa using f.ExtendImg hy hy2
        simpa [hzb, hzcb z hz] using this z hz
  }

/-- Extend preserves the function on its support -/
theorem extend_mono (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) :
    ∀ y ∈ f.Dom, y ∈ (f.extend hx).Dom ∧ (f.extend hx).f y = f.f y := by
  intro y hy
  by_cases hf : f.f x ∈ f.Dom
  · simp [extend, hf, hy]
  · simp [extend, hf]
    by_cases hyf : y = f.f x
    · exact (hf (hyf ▸ hy)).elim
    · have : y ≠ f.freshGenerator - f.f x := (f.fresh_ne_add_f _ hy hx).symm ∘ add_eq_of_eq_sub
      simp [hyf, hy, this]

theorem extend_mono_dom (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) :
    ∀ y ∈ f.Dom, y ∈ (f.extend hx).Dom :=
  fun y hy ↦ ((f.extend_mono hx) y hy).1

theorem extend_mono_f (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) :
    ∀ y ∈ f.Dom, (f.extend hx).f y = f.f y :=
  fun y hy ↦ ((f.extend_mono hx) y hy).2

/-- Extend makes sure that f x is in the domain -/
theorem extend_dom (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) :
    (f.extend hx).f x ∈ (f.extend hx).Dom := by
  by_cases hf : f.f x ∈ f.Dom
  · simp [extend, hf]
  · simp [extend, hf]
    by_cases hxf : x = f.f x
    · exact (hf (hxf ▸ hx)).elim
    · have : x ≠ f.freshGenerator - f.f x := (f.fresh_ne_add_f _ hx hx).symm ∘ add_eq_of_eq_sub
      simp [hxf, this]

/-- Extend makes sure that x obeys the functional equation -/
theorem extend_valid (f : PartialSolution) {x : A} (hx : x ∈ f.Dom) :
    let f' := (f.extend hx).f; f' (f' (f' x) - f' x) = x - f' x :=
  (f.extend hx).Valid (f.extend_mono_dom hx x hx) (f.extend_dom hx)

/-- Extend a partial solution with an element *not* in its domain. -/
def add (f : PartialSolution) {x : A} (hx : x ∉ f.Dom) (hxi : x ∉ f.Im)
    (hxs : ¬∃ w, w ∈ f.Dom ∧ w - f.f w = x)
    : PartialSolution :=
  have hx₀ : x ≠ 0 := fun h ↦ hx (h ▸ f.Dom0 : x ∈ f.Dom)
  let b := f.freshGenerator x;
  --Facts about the fresh generators not being in the domain
  have hbdom : b ∉ f.Dom := f.freshGenerator_not_dom x
  have hxb : x - b ∉ f.Dom := fun h ↦
    (show x - f.freshGenerator x ≠ x - b
      by simpa [add_comm _ x, ← sub_eq_add_neg] using
        f.fresh_sum_ne_sum x h f.Dom0 (-1) 1 0 0 0 0 0 0 1 0 0) rfl
  have hb₀ : b ≠ 0 := by
    simpa using
      f.fresh_ne_sum x f.Dom0 f.Dom0 1
  have hbx : b ≠ x := by
    simpa using f.fresh_ne_sum x f.Dom0 f.Dom0 1 1
  have hb2 : ∀ z ∈ f.Dom, x - b ≠ z - f.f z := fun _ hz ↦ by
    simpa [add_comm, ← sub_eq_add_neg] using
      f.fresh_sum_ne_sum x hz f.Dom0 (-1) 1 0 0 0 0 0 0 1 0 (-1)
  have hbxb : b ≠ x - b := by
    simpa [add_comm, ← sub_eq_add_neg] using
      f.fresh_sum_ne_sum x f.Dom0 f.Dom0 1 0 0 0 0 0 (-1) 1
  have hb3 : ∀ z ∈ f.Dom, f.f z ≠ x - b := fun _ hz ↦ by
    simpa [add_comm, ← sub_eq_add_neg] using
      f.fresh_sum_ne_sum x hz f.Dom0 0 0 0 0 1 0 (-1) 1
  have hb4 : ∀ z ∈ f.Dom, b ≠ z - f.f z := fun _ hz ↦ by
    simpa [sub_eq_add_neg] using
      f.fresh_ne_sum x hz f.Dom0 1 0 1 0 (-1)
  {
    Dom := insert x f.Dom
    f := fun y ↦ if x = y then b else f.f y
    Inj := by
      intro y hy z hz
      simp only [Finset.coe_insert, Set.mem_insert_iff, Finset.mem_coe] at hy hz
      rcases hy with rfl|hy <;> rcases hz with rfl|hz
      · simp
      · have hyz : y ≠ z := fun h ↦ hx (h ▸ hz)
        simp only [hyz, ↓reduceIte, imp_false, ← ne_eq]
        symm
        exact (f.fresh_ne_f y hz).symm
      · have hyz : y ≠ z := fun h ↦ hx (h ▸ hy)
        simp only [hyz.symm, hyz, ↓reduceIte, imp_false, ← ne_eq]
        exact (f.fresh_ne_f z hy).symm
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        have hxz : x ≠ z := fun h ↦ hx (h ▸ hz)
        simp only [hxy, hxz, ↓reduceIte]
        exact f.Inj hy hz
    Dom0 := by simp [f.Dom0]
    Id := by simp [hx₀, f.Id]
    Closed_sub := by
      intro y hy
      rw [Finset.mem_insert] at hy
      rcases hy with rfl|hy
      · simp [hbx, hbdom]
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        have hxy2 : f.f y ≠ x := fun h ↦ hxi (by simp [Im]; use y)
        simp only [hxy, hxy2, hxy2.symm, false_or, ↓reduceIte, Finset.mem_insert]
        exact fun h ↦ Or.inr (f.Closed_sub hy h)
    Valid := by
      intro y hy
      rw [Finset.mem_insert] at hy
      rcases hy with rfl|hy
      · simp [hbx, hbdom]
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        have hxy2 : f.f y ≠ x := fun h ↦ hxi (by simp [Im]; use y)
        simp only [hxy, hxy2, hxy2.symm, false_or, ↓reduceIte, Finset.mem_insert]
        intro hy2
        have hxy3 : x ≠ f.f (f.f y) - f.f y := fun h ↦ hx (h ▸ f.Closed_sub hy hy2)
        rw [if_neg hxy3]
        exact f.Valid hy hy2
    SubInj := by
      intro y z hy hz
      simp only [Finset.mem_insert, @eq_comm _ _ x] at hy hz
      rcases hy with rfl|hy <;> rcases hz with rfl|hz
      · simp
      · have hxz : x ≠ z := fun h ↦ hx (h ▸ hz)
        simp only [hxz, ↓reduceIte, imp_false, ← ne_eq]
        exact hb2 z hz
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        simp only [hxy, ↓reduceIte, imp_false, ← ne_eq]
        exact fun h ↦ ((hb2 y hy).symm h).elim
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        have hxz : x ≠ z := fun h ↦ hx (h ▸ hz)
        simp only [hxy, hxz, ↓reduceIte, imp_false, ← ne_eq]
        exact f.SubInj hy hz
    ExtendDom := by
      intro y hy
      simp only [Finset.mem_insert, @eq_comm _ _ x] at hy
      rcases hy with rfl|hy
      · simp [hb₀, hxb]
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        simp only [hxy, ↓reduceIte, Finset.mem_insert, not_or, and_imp]
        intro _ h₂
        have hxy2 : y - f.f y ≠ x := by
          simp only [not_exists, not_and] at hxs
          exact hxs y hy
        simpa [hxy2, not_false_eq_true, true_and] using f.ExtendDom hy h₂
    ExtendImg := by
      intro y hy
      simp only [Finset.mem_insert, @eq_comm _ _ x] at hy
      rcases hy with rfl|hy
      · simp [hbdom, hbxb, hbx]
        intro z hz
        have hxz : x ≠ z := fun h ↦ hx (h ▸ hz)
        simp [hxz, hb3 z hz]
      · have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
        simp [hxy, hb4 y hy]
        intro _ h₂ z hz
        have hxz : x ≠ z := fun h ↦ hx (h ▸ hz)
        have := f.ExtendImg hy h₂
        simp [hxz] at this ⊢
        exact this z hz
  }

/-- Add preserves the function on its domain -/
theorem add_mono (f : PartialSolution) {x : A} (hx : x ∉ f.Dom) (hxi : x ∉ f.Im)
    (hxs : ¬∃ w, w ∈ f.Dom ∧ w - f.f w = x) :
    ∀ y ∈ f.Dom, y ∈ (f.add hx hxi hxs).Dom ∧ (f.add hx hxi hxs).f y = f.f y := by
  intro y hy
  have hxy : x ≠ y := fun h ↦ hx (h ▸ hy)
  simp [add, hy, hxy]

theorem add_mono_dom (f : PartialSolution) {x : A} (hx : x ∉ f.Dom) (hxi : x ∉ f.Im)
    (hxs : ¬∃ w, w ∈ f.Dom ∧ w - f.f w = x) :
    ∀ y ∈ f.Dom, y ∈ (f.add hx hxi hxs).Dom :=
  fun y hy ↦ (f.add_mono hx hxi hxs y hy).1

theorem add_mono_f (f : PartialSolution) {x : A} (hx : x ∉ f.Dom) (hxi : x ∉ f.Im)
    (hxs : ¬∃ w, w ∈ f.Dom ∧ w - f.f w = x) :
    ∀ y ∈ f.Dom, (f.add hx hxi hxs).f y = f.f y :=
  fun y hy ↦ (f.add_mono hx hxi hxs y hy).2

/-- The added partial solution has the new element in the domain. -/
theorem add_dom (f : PartialSolution) {x : A} (hx : x ∉ f.Dom) (hxi : x ∉ f.Im)
    (hxs : ¬∃ w, w ∈ f.Dom ∧ w - f.f w = x) :
    x ∈ (f.add hx hxi hxs).Dom := by
  simp [add]

private lemma closeImg.lem_1 {f : PartialSolution} {x : Obelix.A} (hxi : x ∈ f.Im) :
    ∃! a, a ∈ f.Dom ∧ (fun x_1 ↦ f.f x_1 = x) a := by
  obtain ⟨y,hy₁,hy₂⟩ := Finset.mem_image.mp hxi;
  use y
  simp [hy₁, hy₂]
  exact fun _ hz ↦ hy₂ ▸ (f.Inj hz hy₁)

private lemma closeImg.lem_2 {f : PartialSolution} {x : Obelix.A} (hxi : x ∈ f.Im) :
    let y := Finset.choose (fun x_1 ↦ f.f x_1 = x) f.Dom (lem_1 hxi);
    y ∈ f.Dom :=
  Finset.choose_mem _ _ _

private lemma closeImg.lem_3 {f : PartialSolution} {x : Obelix.A} (hxi : x ∈ f.Im) :
    let y := Finset.choose (fun x_1 ↦ f.f x_1 = x) f.Dom (lem_1 hxi);
    ∀ (hy : y ∈ f.Dom := lem_2 hxi), x ∈ (f.extend hy).Dom := by
  intro y hy
  rw [← show (f.extend hy).f y = x from (f.extend_mono_f _ _ hy).trans
    (Finset.choose_spec (f.f · = x) _ _).2]
  exact f.extend_dom hy

def closeImg (f : PartialSolution) (x : A) (hxi : x ∈ f.Im) : PartialSolution :=
  --If x is in the image but not the domain, find the unique y such that f(y) = x
    let y : A := Finset.choose (f.f · = x) f.Dom (closeImg.lem_1 hxi)
    have hy : y ∈ f.Dom := closeImg.lem_2 hxi
    --And then `extend y` (so that x is in the domain), and finally `extend x`
    (f.extend hy).extend (closeImg.lem_3 hxi hy)

private lemma close.lem_1 {f : PartialSolution} {x : Obelix.A}
    (hw₀ : ∃! a, a ∈ f.Dom ∧ (fun w ↦ w - f.f w = x) a) :
    let w := Finset.choose (fun w ↦ w - f.f w = x) f.Dom hw₀;
    ∀ (hw : w ∈ f.Dom), x ∈ (f.extend hw).Im := by
  intro w hw
  have hw₂ := f.extend_mono_dom hw _ hw
  simp only [Im, Finset.mem_image]
  use (f.extend hw).f ((f.extend hw).f w) - (f.extend hw).f w
  constructor
  · exact (f.extend hw).Closed_sub hw₂ (f.extend_dom hw)
  · have hfw₂ : w - (f.extend hw).f w = x := (f.extend_mono_f _ w hw) ▸
      (Finset.choose_spec (fun w ↦ w - f.f w = x) _ _).2
    rw [← hfw₂]
    exact (f.extend hw).Valid hw₂ (f.extend_dom hw)

/-- Given f, (possibly) extend it to ensure that x is in the domain, image, and obeys the functional
  equation. This is done by possibly using `add` to include x, and then `extend`. -/
def close (f : PartialSolution) (x : A) : PartialSolution :=
  if hx : x ∈ f.Dom then
    --If x is in the domain, just make sure that it obeys the functional equation with `extend`.
    f.extend hx
  else if hxi : x ∈ f.Im then
    f.closeImg x hxi
  else if hxs : ∃ w, w ∈ f.Dom ∧ w - f.f w = x then
    --If x is in the image but not the domain, find the unique y such that f(y) = x
    let w : A := Finset.choose (fun w ↦ w - f.f w = x) f.Dom (by
      obtain ⟨y,hy₁,hy₂⟩ := hxs;
      use y
      simp [hy₁, hy₂]
      exact fun _ hz ↦ hy₂ ▸ (f.SubInj hz hy₁)
    )
    have hw : w ∈ f.Dom := Finset.choose_mem _ _ _
    --And then `extend y` (so that x is in the domain), and finally `extend x`
    (f.extend hw).closeImg x (close.lem_1 _ _)
  else
    --Otherwise x is in neither the domain nor the image and we use `add`, `extend`.
    (f.add hx hxi hxs).extend (f.add_dom hx hxi hxs)

/-- The closed partial solution has the new element `x` in the domain. -/
theorem close_dom (f : PartialSolution) {x : A} :
    x ∈ (f.close x).Dom := by
  rw [close]
  split_ifs with h₁ h₂
  · apply extend_mono_dom
    exact h₁
  · rw [closeImg]
    apply extend_mono_dom
    exact closeImg.lem_3 h₂
  · rename_i h
    simp only [closeImg]
    apply extend_mono_dom
    exact closeImg.lem_3 (close.lem_1 _ _)
  · apply extend_mono_dom
    apply add_dom

/-- The closed partial solution has `f x` in the domain. -/
theorem close_f_dom (f : PartialSolution) {x : A} :
    (f.close x).f x ∈ (f.close x).Dom := by
  rw [close]
  split_ifs
  · apply extend_dom
  · rw [closeImg]
    apply extend_dom
  · simp only [closeImg]
    apply extend_dom
  · apply extend_dom

theorem close_mono (f : PartialSolution) (x : A) :
    ∀ y, y ∈ f.Dom → y ∈ (f.close x).Dom := by
  rw [close]
  split_ifs
  · apply extend_mono_dom
  · intro y hy
    rw [closeImg]
    apply extend_mono_dom
    apply extend_mono_dom _ _ _ hy
  · simp only [closeImg]
    intro y hy
    repeat apply extend_mono_dom
    exact hy
  · intro y hy
    apply extend_mono_dom
    exact add_mono_dom _ _ _ _ _ hy

theorem close_extend (f : PartialSolution) (x : A) :
    ∀ y, y ∈ f.Dom → (f.close x).f y = f.f y := by
  rw [close]
  split_ifs
  · apply extend_mono_f
  · intro y hy
    rw [closeImg, extend_mono_f]
    apply extend_mono_f _ _ _ hy
    exact extend_mono_dom _ _ _ hy
  · simp only [closeImg]
    intro y hy
    repeat rw [extend_mono_f _ _ _]
    all_goals repeat apply extend_mono_dom
    all_goals assumption
  · intro y hy
    rw [extend_mono_f]
    exact add_mono_f _ _ _ _ _ hy
    exact add_mono_dom _ _ _ _ _ hy

/-- Repeatedly extend f by the least element not in its domain, and the bifurcation tree that element
  generates. -/
def closureSeq (f : PartialSolution) : ℕ → PartialSolution
| 0 => f
| n+1 => (closureSeq f n).close (Denumerable.ofNat A n)

theorem mem_closureSeq (f : PartialSolution) (x : A) :
    x ∈ (f.closureSeq (Encodable.encode x + 1)).Dom := by
  rw [closureSeq.eq_def]
  simp only [Denumerable.ofNat_encode _]
  apply close_dom

theorem mem_f_closureSeq (f : PartialSolution) (x : A) :
    (f.closureSeq (Encodable.encode x + 1)).f x ∈ (f.closureSeq (Encodable.encode x + 1)).Dom := by
  rw [closureSeq.eq_def]
  simp only [Denumerable.ofNat_encode _]
  apply close_f_dom

theorem closureSeq_mono (f : PartialSolution) (n : ℕ) :
    ∀ x, x ∈ f.Dom → x ∈ (f.closureSeq n).Dom := by
  induction n
  · simp [closureSeq]
  next k ih =>
    rw [closureSeq]
    intro x hx
    apply (f.closureSeq k).close_mono _ _ (ih x hx)

theorem closureSeq_extends (f : PartialSolution) (n : ℕ) :
    ∀ x, x ∈ f.Dom → (f.closureSeq n).f x = f.f x := by
  induction n
  · simp [closureSeq]
  next k ih =>
    rw [closureSeq]
    intro x hx
    rw [(f.closureSeq k).close_extend _ x (f.closureSeq_mono _ _ hx)]
    exact ih x hx


theorem closureSeq_ascDom (f : PartialSolution) (n k : ℕ) :
    ∀ x, x ∈ (f.closureSeq n).Dom → x ∈ (f.closureSeq (n+k)).Dom := by
  induction k
  · simp [closureSeq]
  next k ih =>
    intro x hx
    rw [← add_assoc, closureSeq]
    exact (f.closureSeq _).close_mono _ _ (ih x hx)

theorem closureSeq_asc (f : PartialSolution) (n k : ℕ) :
    ∀ x, x ∈ (f.closureSeq n).Dom → (f.closureSeq (n+k)).f x = (f.closureSeq n).f x := by
  induction k
  · simp [closureSeq]
  next k ih =>
    intro x hx
    rw [← add_assoc, closureSeq]
    rw [(f.closureSeq _).close_extend _ x (f.closureSeq_ascDom _ _ _ hx)]
    exact ih x hx

/-- Make the linearizing function f from the closure. -/
def closureLinear (f : PartialSolution) : A → A :=
  fun a ↦ (f.closureSeq (Encodable.encode a + 1)).f a

theorem closureLinear_eq_closureSeq (f : PartialSolution) (n : ℕ) (a : A) (hn : a ∈ (closureSeq f n).Dom) :
    f.closureLinear a = (f.closureSeq n).f a := by
  simp only [closureLinear]
  rcases le_total n (Encodable.encode a + 1) with h | h
  · obtain ⟨k,hk⟩ := Nat.le.dest h
    rw [← hk]
    exact closureSeq_asc _ _ _ _ hn
  · obtain ⟨k,hk⟩ := Nat.le.dest h
    rw [← hk]
    symm
    apply closureSeq_asc
    apply mem_closureSeq

set_option maxHeartbeats 800000 in
/-- The linearizing function satisfies the functional equation, f( f(f(x)) - f(x) ) = x - f(x). -/
theorem closureLinear_funeq (f₀ : PartialSolution) :
    let f := closureLinear f₀;
    ∀ x, f (f (f x) - f x) = x - f x := by
  dsimp
  intro x
  have hx₁ : x ∈ (f₀.closureSeq (Encodable.encode x + 1)).Dom :=
    f₀.mem_closureSeq x
  have hx₂ : (f₀.closureSeq (Encodable.encode x + 1)).f x ∈ (f₀.closureSeq (Encodable.encode x + 1)).Dom :=
    f₀.mem_f_closureSeq x
  rw [f₀.closureLinear_eq_closureSeq (Encodable.encode x + 1) x hx₁]
  rw [f₀.closureLinear_eq_closureSeq (Encodable.encode x + 1) _ hx₂]
  rw [f₀.closureLinear_eq_closureSeq (Encodable.encode x + 1)]
  · apply PartialSolution.Valid _ hx₁ hx₂
  · apply PartialSolution.Closed_sub _ hx₁ hx₂

/-- The linearizing function agrees with the initial PartialSolution on its support. -/
theorem closureLinear_extends (f₀ : PartialSolution) :
    ∀ x, (h : x ∈ f₀.Dom) → closureLinear f₀ x = f₀.f x :=
  fun x ↦ closureSeq_extends _ _ x

/-- Define the magma from the linearizing function. -/
def closure (f : PartialSolution) : A → A → A :=
  fun a b ↦ a + (closureLinear f) (b - a)

/-- The resulting magma obeys the Obelix rule. -/
theorem closure_prop (f : PartialSolution) : ∀ x y,
    x = closure f (closure f y x) (closure f y (closure f y x)) :=
  fun x y ↦ by simp [closure, closureLinear_funeq f (x - y)]

private abbrev x₁ : A := fun₀ | 0 => 1
private abbrev x₂ : A := fun₀ | 1 => 1
private abbrev x₃ : A := fun₀ | 2 => 1
private abbrev x₄ : A := fun₀ | 3 => 1

/-- An initial solution, given by the empty partial function. -/
def initial : PartialSolution where
  Dom := {0, x₁, x₂ - x₁, x₁ + x₃}
  f := (fun₀ | x₁ => x₂ | x₂ - x₁ => x₃ | x₁ + x₃ => x₄ : DFinsupp _)
  Inj := by
    intro x hx y hy
    simp only [Finset.coe_insert, Finset.coe_singleton] at hx hy
    rcases hx with (rfl|rfl|rfl|rfl)
    <;> rcases hy with (rfl|rfl|rfl|rfl)
    <;> decide
  Dom0 := by simp
  Id := by repeat rw [DFinsupp.coe_update, Function.update_of_ne] <;> decide
  Closed_sub := by decide
  Valid := by decide
  SubInj := by
    intro a b
    simp only [Finset.mem_insert, Finset.mem_singleton]
    rintro (rfl|rfl|rfl|rfl)
    <;> rintro (rfl|rfl|rfl|rfl)
    <;> decide
  ExtendDom := by decide
  ExtendImg := by
    intro
    simp only [Finset.mem_insert, Finset.mem_singleton, ← Finset.coe_image]
    rintro (rfl|rfl|rfl|rfl) <;> decide

@[equational_result]
theorem Equation1491_facts : ∃ (G : Type) (_ : Magma G), Facts G [1491] [65] := by
  use A, ⟨initial.closure⟩
  simp only [Equation1491, closure_prop, implies_true, not_forall, true_and]
  constructor
  · exact closure_prop initial
  · use 0, -x₁
    nth_rewrite 3 [closure]
    rw [sub_neg_eq_add, zero_add, initial.closureLinear_extends x₁ (by decide)]
    rw [show initial.f x₁ = x₂ by decide]
    nth_rewrite 2 [closure]
    rw [sub_zero, zero_add, add_comm, initial.closureLinear_extends (x₂+(-x₁)) (by decide)]
    rw [show initial.f (x₂+(-x₁)) = x₃ by decide]
    rw [closure]
    rw [sub_neg_eq_add, add_comm x₃, initial.closureLinear_extends (x₁+x₃) (by decide)]
    rw [show initial.f (x₁+x₃) = x₄ by decide]
    decide
