
import Mathlib.Data.Finite.Prod
import equational_theories.Equations.All
import equational_theories.FactsSyntax
import equational_theories.MemoFinOp
import equational_theories.DecideBang

/-!
This file is generated from the following operator table:
[[0,0,1,0],[3,1,3,1],[2,2,2,2],[1,3,0,3]]
-/

set_option linter.unusedVariables false

/-! The magma definition -/
def «All4x4Tables [[0,0,1,0],[3,1,3,1],[2,2,2,2],[1,3,0,3]]» : Magma (Fin 4) where
  op := finOpTable "[[0,0,1,0],[3,1,3,1],[2,2,2,2],[1,3,0,3]]"

/-! The facts -/
@[equational_result]
theorem «Facts from All4x4Tables [[0,0,1,0],[3,1,3,1],[2,2,2,2],[1,3,0,3]]» :
  ∃ (G : Type) (_ : Magma G) (_: Finite G), Facts G [3317] [3459] :=
    ⟨Fin 4, «All4x4Tables [[0,0,1,0],[3,1,3,1],[2,2,2,2],[1,3,0,3]]», Finite.of_fintype _, by decideFin!⟩
