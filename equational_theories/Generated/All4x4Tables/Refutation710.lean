
import Mathlib.Data.Finite.Prod
import equational_theories.Equations.All
import equational_theories.FactsSyntax
import equational_theories.MemoFinOp
import equational_theories.DecideBang

/-!
This file is generated from the following operator table:
[[1,1,5,1,5,1],[2,4,4,2,4,4],[3,0,3,3,3,0],[5,5,1,5,1,5],[0,3,0,0,0,3],[4,2,2,4,2,2]]
-/

set_option linter.unusedVariables false

/-! The magma definition -/
def «All4x4Tables [[1,1,5,1,5,1],[2,4,4,2,4,4],[3,0,3,3,3,0],[5,5,1,5,1,5],[0,3,0,0,0,3],[4,2,2,4,2,2]]» : Magma (Fin 6) where
  op := finOpTable "[[1,1,5,1,5,1],[2,4,4,2,4,4],[3,0,3,3,3,0],[5,5,1,5,1,5],[0,3,0,0,0,3],[4,2,2,4,2,2]]"

/-! The facts -/
@[equational_result]
theorem «Facts from All4x4Tables [[1,1,5,1,5,1],[2,4,4,2,4,4],[3,0,3,3,3,0],[5,5,1,5,1,5],[0,3,0,0,0,3],[4,2,2,4,2,2]]» :
  ∃ (G : Type) (_ : Magma G) (_: Finite G), Facts G [2045, 2675] [255, 2037, 2040, 2050, 2053, 2054, 2060, 2063, 2650, 2652, 2659, 2660, 2662, 2847, 3258, 3261, 3306, 3309, 3315, 3316, 3318, 3319, 3456, 4269, 4284, 4598, 4599, 4631, 4656] :=
    ⟨Fin 6, «All4x4Tables [[1,1,5,1,5,1],[2,4,4,2,4,4],[3,0,3,3,3,0],[5,5,1,5,1,5],[0,3,0,0,0,3],[4,2,2,4,2,2]]», Finite.of_fintype _, by decideFin!⟩
