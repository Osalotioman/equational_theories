
import Mathlib.Data.Finite.Prod
import equational_theories.Equations.All
import equational_theories.FactsSyntax
import equational_theories.MemoFinOp
import equational_theories.DecideBang

/-!
This file is generated from the following refutation as produced by
random generation of polynomials:
'(3 * x**2 + 0 * y**2 + 1 * x + 0 * y + 2 * x * y) % 4' (0, 358, 359, 376, 377, 378, 3658, 3659, 3660, 3661, 3662, 3720, 3721, 3722, 3723, 3724, 3725, 3726, 3727, 3728, 3729, 4064, 4065, 4066, 4067, 4068, 4126, 4127, 4128, 4129, 4130, 4131, 4132, 4133, 4134, 4135, 4267, 4268, 4269, 4270, 4281, 4282, 4283, 4284, 4285, 4286, 4287, 4288, 4313, 4314, 4315, 4316, 4317, 4318, 4338, 4339, 4340, 4341, 4356, 4357, 4358, 4359, 4360, 4582, 4596, 4628, 4629, 4653, 4671)
-/

set_option linter.unusedVariables false

/-! The magma definition -/
def «FinitePoly 3 * x² + x + 2 * x * y % 4» : Magma (Fin 4) where
  op := memoFinOp fun x y => 3 * x*x + x + 2 * x * y

/-! The facts -/
@[equational_result]
theorem «Facts from FinitePoly 3 * x² + x + 2 * x * y % 4» :
  ∃ (G : Type) (_ : Magma G) (_: Finite G), Facts G [379, 4271] [47, 99, 151, 203, 255, 411, 614, 817, 1020, 1223, 1426, 1629, 1832, 2035, 2238, 2441, 2644, 2847, 3050, 3253, 3456, 3664, 3665, 3667, 3668, 3674, 3675, 3677, 3678, 3684, 3685, 3687, 3712, 3714, 3748, 3749, 3751, 3752, 3759, 3761, 3862, 4070, 4071, 4073, 4074, 4080, 4081, 4083, 4084, 4090, 4091, 4093, 4118, 4120, 4121, 4155, 4157, 4158, 4164, 4165, 4167, 4272, 4273, 4275, 4276, 4290, 4291, 4293, 4320, 4321, 4343, 4380, 4584, 4585, 4587, 4588, 4590, 4591, 4598, 4599, 4605, 4606, 4608, 4635, 4636, 4658] :=
    ⟨Fin 4, «FinitePoly 3 * x² + x + 2 * x * y % 4», Finite.of_fintype _, by decideFin!⟩
