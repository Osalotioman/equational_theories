
import Mathlib.Data.Finite.Prod
import equational_theories.Equations.All
import equational_theories.FactsSyntax
import equational_theories.MemoFinOp
import equational_theories.DecideBang

/-!
This file is generated from the following operator table:
[[1,1,4,4,1],[2,1,3,1,1],[1,1,1,1,1],[1,1,1,1,0],[1,1,1,1,1]]
-/

set_option linter.unusedVariables false

/-! The magma definition -/
def «All4x4Tables [[1,1,4,4,1],[2,1,3,1,1],[1,1,1,1,1],[1,1,1,1,0],[1,1,1,1,1]]» : Magma (Fin 5) where
  op := finOpTable "[[1,1,4,4,1],[2,1,3,1,1],[1,1,1,1,1],[1,1,1,1,0],[1,1,1,1,1]]"

/-! The facts -/
@[equational_result]
theorem «Facts from All4x4Tables [[1,1,4,4,1],[2,1,3,1,1],[1,1,1,1,1],[1,1,1,1,0],[1,1,1,1,1]]» :
  ∃ (G : Type) (_ : Magma G) (_: Finite G), Facts G [3273] [3261, 3269] :=
    ⟨Fin 5, «All4x4Tables [[1,1,4,4,1],[2,1,3,1,1],[1,1,1,1,1],[1,1,1,1,0],[1,1,1,1,1]]», Finite.of_fintype _, by decideFin!⟩
