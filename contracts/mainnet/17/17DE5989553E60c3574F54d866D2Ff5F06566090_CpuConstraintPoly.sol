/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

contract CpuConstraintPoly {
    // The Memory map during the execution of this contract is as follows:
    // [0x0, 0x20) - periodic_column/pedersen/points/x.
    // [0x20, 0x40) - periodic_column/pedersen/points/y.
    // [0x40, 0x60) - periodic_column/ecdsa/generator_points/x.
    // [0x60, 0x80) - periodic_column/ecdsa/generator_points/y.
    // [0x80, 0xa0) - periodic_column/poseidon/poseidon/full_round_key0.
    // [0xa0, 0xc0) - periodic_column/poseidon/poseidon/full_round_key1.
    // [0xc0, 0xe0) - periodic_column/poseidon/poseidon/full_round_key2.
    // [0xe0, 0x100) - periodic_column/poseidon/poseidon/partial_round_key0.
    // [0x100, 0x120) - periodic_column/poseidon/poseidon/partial_round_key1.
    // [0x120, 0x140) - trace_length.
    // [0x140, 0x160) - offset_size.
    // [0x160, 0x180) - half_offset_size.
    // [0x180, 0x1a0) - initial_ap.
    // [0x1a0, 0x1c0) - initial_pc.
    // [0x1c0, 0x1e0) - final_ap.
    // [0x1e0, 0x200) - final_pc.
    // [0x200, 0x220) - memory/multi_column_perm/perm/interaction_elm.
    // [0x220, 0x240) - memory/multi_column_perm/hash_interaction_elm0.
    // [0x240, 0x260) - memory/multi_column_perm/perm/public_memory_prod.
    // [0x260, 0x280) - rc16/perm/interaction_elm.
    // [0x280, 0x2a0) - rc16/perm/public_memory_prod.
    // [0x2a0, 0x2c0) - rc_min.
    // [0x2c0, 0x2e0) - rc_max.
    // [0x2e0, 0x300) - diluted_check/permutation/interaction_elm.
    // [0x300, 0x320) - diluted_check/permutation/public_memory_prod.
    // [0x320, 0x340) - diluted_check/first_elm.
    // [0x340, 0x360) - diluted_check/interaction_z.
    // [0x360, 0x380) - diluted_check/interaction_alpha.
    // [0x380, 0x3a0) - diluted_check/final_cum_val.
    // [0x3a0, 0x3c0) - pedersen/shift_point.x.
    // [0x3c0, 0x3e0) - pedersen/shift_point.y.
    // [0x3e0, 0x400) - initial_pedersen_addr.
    // [0x400, 0x420) - initial_rc_addr.
    // [0x420, 0x440) - ecdsa/sig_config.alpha.
    // [0x440, 0x460) - ecdsa/sig_config.shift_point.x.
    // [0x460, 0x480) - ecdsa/sig_config.shift_point.y.
    // [0x480, 0x4a0) - ecdsa/sig_config.beta.
    // [0x4a0, 0x4c0) - initial_ecdsa_addr.
    // [0x4c0, 0x4e0) - initial_bitwise_addr.
    // [0x4e0, 0x500) - initial_ec_op_addr.
    // [0x500, 0x520) - ec_op/curve_config.alpha.
    // [0x520, 0x540) - initial_poseidon_addr.
    // [0x540, 0x560) - trace_generator.
    // [0x560, 0x580) - oods_point.
    // [0x580, 0x640) - interaction_elements.
    // [0x640, 0x1ea0) - coefficients.
    // [0x1ea0, 0x4040) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x4040, 0x4060) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x4060, 0x4080) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x4080, 0x40a0) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x40a0, 0x40c0) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x40c0, 0x40e0) - intermediate_value/cpu/decode/flag_op1_base_op0_0.
    // [0x40e0, 0x4100) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x4100, 0x4120) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x4120, 0x4140) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x4140, 0x4160) - intermediate_value/cpu/decode/flag_res_op1_0.
    // [0x4160, 0x4180) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x4180, 0x41a0) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x41a0, 0x41c0) - intermediate_value/cpu/decode/flag_pc_update_regular_0.
    // [0x41c0, 0x41e0) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x41e0, 0x4200) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x4200, 0x4220) - intermediate_value/cpu/decode/fp_update_regular_0.
    // [0x4220, 0x4240) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x4240, 0x4260) - intermediate_value/npc_reg_0.
    // [0x4260, 0x4280) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x4280, 0x42a0) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x42a0, 0x42c0) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x42c0, 0x42e0) - intermediate_value/memory/address_diff_0.
    // [0x42e0, 0x4300) - intermediate_value/rc16/diff_0.
    // [0x4300, 0x4320) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x4320, 0x4340) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x4340, 0x4360) - intermediate_value/rc_builtin/value0_0.
    // [0x4360, 0x4380) - intermediate_value/rc_builtin/value1_0.
    // [0x4380, 0x43a0) - intermediate_value/rc_builtin/value2_0.
    // [0x43a0, 0x43c0) - intermediate_value/rc_builtin/value3_0.
    // [0x43c0, 0x43e0) - intermediate_value/rc_builtin/value4_0.
    // [0x43e0, 0x4400) - intermediate_value/rc_builtin/value5_0.
    // [0x4400, 0x4420) - intermediate_value/rc_builtin/value6_0.
    // [0x4420, 0x4440) - intermediate_value/rc_builtin/value7_0.
    // [0x4440, 0x4460) - intermediate_value/ecdsa/signature0/doubling_key/x_squared.
    // [0x4460, 0x4480) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0.
    // [0x4480, 0x44a0) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0.
    // [0x44a0, 0x44c0) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_0.
    // [0x44c0, 0x44e0) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0.
    // [0x44e0, 0x4500) - intermediate_value/bitwise/sum_var_0_0.
    // [0x4500, 0x4520) - intermediate_value/bitwise/sum_var_8_0.
    // [0x4520, 0x4540) - intermediate_value/ec_op/doubling_q/x_squared_0.
    // [0x4540, 0x4560) - intermediate_value/ec_op/ec_subset_sum/bit_0.
    // [0x4560, 0x4580) - intermediate_value/ec_op/ec_subset_sum/bit_neg_0.
    // [0x4580, 0x45a0) - intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0.
    // [0x45a0, 0x45c0) - intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_0.
    // [0x45c0, 0x45e0) - intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_0.
    // [0x45e0, 0x4600) - intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7.
    // [0x4600, 0x4620) - intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_7.
    // [0x4620, 0x4640) - intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_7.
    // [0x4640, 0x4660) - intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_3.
    // [0x4660, 0x4680) - intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_3.
    // [0x4680, 0x46a0) - intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_3.
    // [0x46a0, 0x46c0) - intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_0.
    // [0x46c0, 0x46e0) - intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_1.
    // [0x46e0, 0x4700) - intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_2.
    // [0x4700, 0x4720) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_0.
    // [0x4720, 0x4740) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_1.
    // [0x4740, 0x4760) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_2.
    // [0x4760, 0x4780) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_19.
    // [0x4780, 0x47a0) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_20.
    // [0x47a0, 0x47c0) - intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_21.
    // [0x47c0, 0x4e80) - expmods.
    // [0x4e80, 0x53a0) - domains.
    // [0x53a0, 0x56e0) - denominator_invs.
    // [0x56e0, 0x5a20) - denominators.
    // [0x5a20, 0x5ae0) - expmod_context.

    fallback() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x4040)
            let point := /*oods_point*/ mload(0x560)
            function expmod(base, exponent, modulus) -> result {
              let p := /*expmod_context*/ 0x5a20
              mstore(p, 0x20)                 // Length of Base.
              mstore(add(p, 0x20), 0x20)      // Length of Exponent.
              mstore(add(p, 0x40), 0x20)      // Length of Modulus.
              mstore(add(p, 0x60), base)      // Base.
              mstore(add(p, 0x80), exponent)  // Exponent.
              mstore(add(p, 0xa0), modulus)   // Modulus.
              // Call modexp precompile.
              if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
              }
              result := mload(p)
            }
            {
              // Prepare expmods for denominators and numerators.

              // expmods[0] = point^(trace_length / 32768).
              mstore(0x47c0, expmod(point, div(/*trace_length*/ mload(0x120), 32768), PRIME))

              // expmods[1] = point^(trace_length / 16384).
              mstore(0x47e0, mulmod(
                /*point^(trace_length / 32768)*/ mload(0x47c0),
                /*point^(trace_length / 32768)*/ mload(0x47c0),
                PRIME))

              // expmods[2] = point^(trace_length / 1024).
              mstore(0x4800, expmod(point, div(/*trace_length*/ mload(0x120), 1024), PRIME))

              // expmods[3] = point^(trace_length / 512).
              mstore(0x4820, mulmod(
                /*point^(trace_length / 1024)*/ mload(0x4800),
                /*point^(trace_length / 1024)*/ mload(0x4800),
                PRIME))

              // expmods[4] = point^(trace_length / 256).
              mstore(0x4840, mulmod(
                /*point^(trace_length / 512)*/ mload(0x4820),
                /*point^(trace_length / 512)*/ mload(0x4820),
                PRIME))

              // expmods[5] = point^(trace_length / 128).
              mstore(0x4860, mulmod(
                /*point^(trace_length / 256)*/ mload(0x4840),
                /*point^(trace_length / 256)*/ mload(0x4840),
                PRIME))

              // expmods[6] = point^(trace_length / 64).
              mstore(0x4880, mulmod(
                /*point^(trace_length / 128)*/ mload(0x4860),
                /*point^(trace_length / 128)*/ mload(0x4860),
                PRIME))

              // expmods[7] = point^(trace_length / 16).
              mstore(0x48a0, expmod(point, div(/*trace_length*/ mload(0x120), 16), PRIME))

              // expmods[8] = point^(trace_length / 8).
              mstore(0x48c0, mulmod(
                /*point^(trace_length / 16)*/ mload(0x48a0),
                /*point^(trace_length / 16)*/ mload(0x48a0),
                PRIME))

              // expmods[9] = point^(trace_length / 4).
              mstore(0x48e0, mulmod(
                /*point^(trace_length / 8)*/ mload(0x48c0),
                /*point^(trace_length / 8)*/ mload(0x48c0),
                PRIME))

              // expmods[10] = point^(trace_length / 2).
              mstore(0x4900, mulmod(
                /*point^(trace_length / 4)*/ mload(0x48e0),
                /*point^(trace_length / 4)*/ mload(0x48e0),
                PRIME))

              // expmods[11] = point^trace_length.
              mstore(0x4920, mulmod(
                /*point^(trace_length / 2)*/ mload(0x4900),
                /*point^(trace_length / 2)*/ mload(0x4900),
                PRIME))

              // expmods[12] = trace_generator^(trace_length / 64).
              mstore(0x4940, expmod(/*trace_generator*/ mload(0x540), div(/*trace_length*/ mload(0x120), 64), PRIME))

              // expmods[13] = trace_generator^(trace_length / 32).
              mstore(0x4960, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                PRIME))

              // expmods[14] = trace_generator^(3 * trace_length / 64).
              mstore(0x4980, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                PRIME))

              // expmods[15] = trace_generator^(trace_length / 16).
              mstore(0x49a0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(3 * trace_length / 64)*/ mload(0x4980),
                PRIME))

              // expmods[16] = trace_generator^(5 * trace_length / 64).
              mstore(0x49c0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(trace_length / 16)*/ mload(0x49a0),
                PRIME))

              // expmods[17] = trace_generator^(3 * trace_length / 32).
              mstore(0x49e0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(5 * trace_length / 64)*/ mload(0x49c0),
                PRIME))

              // expmods[18] = trace_generator^(7 * trace_length / 64).
              mstore(0x4a00, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(3 * trace_length / 32)*/ mload(0x49e0),
                PRIME))

              // expmods[19] = trace_generator^(trace_length / 8).
              mstore(0x4a20, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(7 * trace_length / 64)*/ mload(0x4a00),
                PRIME))

              // expmods[20] = trace_generator^(9 * trace_length / 64).
              mstore(0x4a40, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(trace_length / 8)*/ mload(0x4a20),
                PRIME))

              // expmods[21] = trace_generator^(5 * trace_length / 32).
              mstore(0x4a60, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(9 * trace_length / 64)*/ mload(0x4a40),
                PRIME))

              // expmods[22] = trace_generator^(11 * trace_length / 64).
              mstore(0x4a80, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(5 * trace_length / 32)*/ mload(0x4a60),
                PRIME))

              // expmods[23] = trace_generator^(3 * trace_length / 16).
              mstore(0x4aa0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(11 * trace_length / 64)*/ mload(0x4a80),
                PRIME))

              // expmods[24] = trace_generator^(13 * trace_length / 64).
              mstore(0x4ac0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(3 * trace_length / 16)*/ mload(0x4aa0),
                PRIME))

              // expmods[25] = trace_generator^(7 * trace_length / 32).
              mstore(0x4ae0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(13 * trace_length / 64)*/ mload(0x4ac0),
                PRIME))

              // expmods[26] = trace_generator^(15 * trace_length / 64).
              mstore(0x4b00, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(7 * trace_length / 32)*/ mload(0x4ae0),
                PRIME))

              // expmods[27] = trace_generator^(trace_length / 2).
              mstore(0x4b20, expmod(/*trace_generator*/ mload(0x540), div(/*trace_length*/ mload(0x120), 2), PRIME))

              // expmods[28] = trace_generator^(19 * trace_length / 32).
              mstore(0x4b40, mulmod(
                /*trace_generator^(3 * trace_length / 32)*/ mload(0x49e0),
                /*trace_generator^(trace_length / 2)*/ mload(0x4b20),
                PRIME))

              // expmods[29] = trace_generator^(5 * trace_length / 8).
              mstore(0x4b60, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(19 * trace_length / 32)*/ mload(0x4b40),
                PRIME))

              // expmods[30] = trace_generator^(21 * trace_length / 32).
              mstore(0x4b80, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(5 * trace_length / 8)*/ mload(0x4b60),
                PRIME))

              // expmods[31] = trace_generator^(11 * trace_length / 16).
              mstore(0x4ba0, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(21 * trace_length / 32)*/ mload(0x4b80),
                PRIME))

              // expmods[32] = trace_generator^(23 * trace_length / 32).
              mstore(0x4bc0, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(11 * trace_length / 16)*/ mload(0x4ba0),
                PRIME))

              // expmods[33] = trace_generator^(3 * trace_length / 4).
              mstore(0x4be0, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(23 * trace_length / 32)*/ mload(0x4bc0),
                PRIME))

              // expmods[34] = trace_generator^(25 * trace_length / 32).
              mstore(0x4c00, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(3 * trace_length / 4)*/ mload(0x4be0),
                PRIME))

              // expmods[35] = trace_generator^(13 * trace_length / 16).
              mstore(0x4c20, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(25 * trace_length / 32)*/ mload(0x4c00),
                PRIME))

              // expmods[36] = trace_generator^(27 * trace_length / 32).
              mstore(0x4c40, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(13 * trace_length / 16)*/ mload(0x4c20),
                PRIME))

              // expmods[37] = trace_generator^(7 * trace_length / 8).
              mstore(0x4c60, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(27 * trace_length / 32)*/ mload(0x4c40),
                PRIME))

              // expmods[38] = trace_generator^(29 * trace_length / 32).
              mstore(0x4c80, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(7 * trace_length / 8)*/ mload(0x4c60),
                PRIME))

              // expmods[39] = trace_generator^(15 * trace_length / 16).
              mstore(0x4ca0, mulmod(
                /*trace_generator^(trace_length / 32)*/ mload(0x4960),
                /*trace_generator^(29 * trace_length / 32)*/ mload(0x4c80),
                PRIME))

              // expmods[40] = trace_generator^(61 * trace_length / 64).
              mstore(0x4cc0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(15 * trace_length / 16)*/ mload(0x4ca0),
                PRIME))

              // expmods[41] = trace_generator^(31 * trace_length / 32).
              mstore(0x4ce0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(61 * trace_length / 64)*/ mload(0x4cc0),
                PRIME))

              // expmods[42] = trace_generator^(251 * trace_length / 256).
              mstore(0x4d00, expmod(/*trace_generator*/ mload(0x540), div(mul(251, /*trace_length*/ mload(0x120)), 256), PRIME))

              // expmods[43] = trace_generator^(63 * trace_length / 64).
              mstore(0x4d20, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(31 * trace_length / 32)*/ mload(0x4ce0),
                PRIME))

              // expmods[44] = trace_generator^(255 * trace_length / 256).
              mstore(0x4d40, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4940),
                /*trace_generator^(251 * trace_length / 256)*/ mload(0x4d00),
                PRIME))

              // expmods[45] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4d60, expmod(/*trace_generator*/ mload(0x540), mul(16, sub(div(/*trace_length*/ mload(0x120), 16), 1)), PRIME))

              // expmods[46] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4d80, expmod(/*trace_generator*/ mload(0x540), mul(2, sub(div(/*trace_length*/ mload(0x120), 2), 1)), PRIME))

              // expmods[47] = trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x4da0, expmod(/*trace_generator*/ mload(0x540), mul(4, sub(div(/*trace_length*/ mload(0x120), 4), 1)), PRIME))

              // expmods[48] = trace_generator^(8 * (trace_length / 8 - 1)).
              mstore(0x4dc0, expmod(/*trace_generator*/ mload(0x540), mul(8, sub(div(/*trace_length*/ mload(0x120), 8), 1)), PRIME))

              // expmods[49] = trace_generator^(512 * (trace_length / 512 - 1)).
              mstore(0x4de0, expmod(/*trace_generator*/ mload(0x540), mul(512, sub(div(/*trace_length*/ mload(0x120), 512), 1)), PRIME))

              // expmods[50] = trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x4e00, expmod(/*trace_generator*/ mload(0x540), mul(256, sub(div(/*trace_length*/ mload(0x120), 256), 1)), PRIME))

              // expmods[51] = trace_generator^(32768 * (trace_length / 32768 - 1)).
              mstore(0x4e20, expmod(/*trace_generator*/ mload(0x540), mul(32768, sub(div(/*trace_length*/ mload(0x120), 32768), 1)), PRIME))

              // expmods[52] = trace_generator^(1024 * (trace_length / 1024 - 1)).
              mstore(0x4e40, expmod(/*trace_generator*/ mload(0x540), mul(1024, sub(div(/*trace_length*/ mload(0x120), 1024), 1)), PRIME))

              // expmods[53] = trace_generator^(16384 * (trace_length / 16384 - 1)).
              mstore(0x4e60, expmod(/*trace_generator*/ mload(0x540), mul(16384, sub(div(/*trace_length*/ mload(0x120), 16384), 1)), PRIME))

            }

            {
              // Compute domains.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // domains[0] = point^trace_length - 1.
              mstore(0x4e80,
                     addmod(/*point^trace_length*/ mload(0x4920), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // domains[1] = point^(trace_length / 2) - 1.
              mstore(0x4ea0,
                     addmod(/*point^(trace_length / 2)*/ mload(0x4900), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // domains[2] = point^(trace_length / 4) - 1.
              mstore(0x4ec0,
                     addmod(/*point^(trace_length / 4)*/ mload(0x48e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'public_memory_addr_zero', 'public_memory_value_zero', 'diluted_check/permutation/step0', 'diluted_check/step', 'poseidon/poseidon/partial_rounds_state0_squaring', 'poseidon/poseidon/partial_round0'.
              // domains[3] = point^(trace_length / 8) - 1.
              mstore(0x4ee0,
                     addmod(/*point^(trace_length / 8)*/ mload(0x48c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/zero'.
              // Numerator for constraints: 'cpu/decode/opcode_rc/bit'.
              // domains[4] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x4f00,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x48a0),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x4ca0)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/decode/flag_op1_base_op0_bit', 'cpu/decode/flag_res_op1_bit', 'cpu/decode/flag_pc_update_regular_bit', 'cpu/decode/fp_update_regular_bit', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/call/off0', 'cpu/opcodes/call/off1', 'cpu/opcodes/call/flags', 'cpu/opcodes/ret/off0', 'cpu/opcodes/ret/off2', 'cpu/opcodes/ret/flags', 'cpu/opcodes/assert_eq/assert_eq', 'poseidon/poseidon/partial_rounds_state1_squaring', 'poseidon/poseidon/partial_round1'.
              // domains[5] = point^(trace_length / 16) - 1.
              mstore(0x4f20,
                     addmod(/*point^(trace_length / 16)*/ mload(0x48a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y', 'ec_op/doubling_q/slope', 'ec_op/doubling_q/x', 'ec_op/doubling_q/y', 'ec_op/ec_subset_sum/booleanity_test', 'ec_op/ec_subset_sum/add_points/slope', 'ec_op/ec_subset_sum/add_points/x', 'ec_op/ec_subset_sum/add_points/y', 'ec_op/ec_subset_sum/add_points/x_diff_inv', 'ec_op/ec_subset_sum/copy_point/x', 'ec_op/ec_subset_sum/copy_point/y', 'poseidon/addr_input_output_step_inner', 'poseidon/poseidon/full_rounds_state0_squaring', 'poseidon/poseidon/full_rounds_state1_squaring', 'poseidon/poseidon/full_rounds_state2_squaring', 'poseidon/poseidon/full_round0', 'poseidon/poseidon/full_round1', 'poseidon/poseidon/full_round2'.
              // domains[6] = point^(trace_length / 64) - 1.
              mstore(0x4f40,
                     addmod(/*point^(trace_length / 64)*/ mload(0x4880), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // domains[7] = point^(trace_length / 128) - 1.
              mstore(0x4f60,
                     addmod(/*point^(trace_length / 128)*/ mload(0x4860), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'rc_builtin/value', 'rc_builtin/addr_step', 'bitwise/step_var_pool_addr', 'bitwise/partition'.
              // domains[8] = point^(trace_length / 256) - 1.
              mstore(0x4f80,
                     addmod(/*point^(trace_length / 256)*/ mload(0x4840), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail'.
              // Numerator for constraints: 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // domains[9] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x4fa0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x4840),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4d40)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end'.
              // domains[10] = point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              mstore(0x4fc0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x4840),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4d20)),
                       PRIME))

              // Numerator for constraints: 'poseidon/poseidon/full_round0', 'poseidon/poseidon/full_round1', 'poseidon/poseidon/full_round2'.
              // domains[11] = point^(trace_length / 256) - trace_generator^(3 * trace_length / 4).
              mstore(0x4fe0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x4840),
                       sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x4be0)),
                       PRIME))

              // Numerator for constraints: 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y'.
              // domains[12] = point^(trace_length / 512) - trace_generator^(trace_length / 2).
              mstore(0x5000,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x4820),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x4b20)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/input0_value0', 'pedersen/input0_addr', 'pedersen/input1_value0', 'pedersen/input1_addr', 'pedersen/output_value0', 'pedersen/output_addr', 'poseidon/addr_input_output_step_outter', 'poseidon/poseidon/add_first_round_key0', 'poseidon/poseidon/add_first_round_key1', 'poseidon/poseidon/add_first_round_key2', 'poseidon/poseidon/last_full_round0', 'poseidon/poseidon/last_full_round1', 'poseidon/poseidon/last_full_round2', 'poseidon/poseidon/copy_partial_rounds0_i0', 'poseidon/poseidon/copy_partial_rounds0_i1', 'poseidon/poseidon/copy_partial_rounds0_i2', 'poseidon/poseidon/margin_full_to_partial0', 'poseidon/poseidon/margin_full_to_partial1', 'poseidon/poseidon/margin_full_to_partial2', 'poseidon/poseidon/margin_partial_to_full0', 'poseidon/poseidon/margin_partial_to_full1', 'poseidon/poseidon/margin_partial_to_full2'.
              // domains[13] = point^(trace_length / 512) - 1.
              mstore(0x5020,
                     addmod(/*point^(trace_length / 512)*/ mload(0x4820), sub(PRIME, 1), PRIME))

              // domains[14] = (point^(trace_length / 512) - trace_generator^(3 * trace_length / 4)) * (point^(trace_length / 512) - trace_generator^(7 * trace_length / 8)).
              mstore(0x5040,
                     mulmod(
                       addmod(
                         /*point^(trace_length / 512)*/ mload(0x4820),
                         sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x4be0)),
                         PRIME),
                       addmod(
                         /*point^(trace_length / 512)*/ mload(0x4820),
                         sub(PRIME, /*trace_generator^(7 * trace_length / 8)*/ mload(0x4c60)),
                         PRIME),
                       PRIME))

              // Numerator for constraints: 'poseidon/addr_input_output_step_inner'.
              // domains[15] = (point^(trace_length / 512) - trace_generator^(5 * trace_length / 8)) * domain14.
              mstore(0x5060,
                     mulmod(
                       addmod(
                         /*point^(trace_length / 512)*/ mload(0x4820),
                         sub(PRIME, /*trace_generator^(5 * trace_length / 8)*/ mload(0x4b60)),
                         PRIME),
                       /*domains[14]*/ mload(0x5040),
                       PRIME))

              // domains[16] = point^(trace_length / 512) - trace_generator^(31 * trace_length / 32).
              mstore(0x5080,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x4820),
                       sub(PRIME, /*trace_generator^(31 * trace_length / 32)*/ mload(0x4ce0)),
                       PRIME))

              // domains[17] = (point^(trace_length / 512) - trace_generator^(11 * trace_length / 16)) * (point^(trace_length / 512) - trace_generator^(23 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(25 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(13 * trace_length / 16)) * (point^(trace_length / 512) - trace_generator^(27 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(29 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(15 * trace_length / 16)) * domain16.
              {
                let domain := mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 512)*/ mload(0x4820),
                          sub(PRIME, /*trace_generator^(11 * trace_length / 16)*/ mload(0x4ba0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 512)*/ mload(0x4820),
                          sub(PRIME, /*trace_generator^(23 * trace_length / 32)*/ mload(0x4bc0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 512)*/ mload(0x4820),
                        sub(PRIME, /*trace_generator^(25 * trace_length / 32)*/ mload(0x4c00)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 512)*/ mload(0x4820),
                      sub(PRIME, /*trace_generator^(13 * trace_length / 16)*/ mload(0x4c20)),
                      PRIME),
                    PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 512)*/ mload(0x4820),
                          sub(PRIME, /*trace_generator^(27 * trace_length / 32)*/ mload(0x4c40)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 512)*/ mload(0x4820),
                          sub(PRIME, /*trace_generator^(29 * trace_length / 32)*/ mload(0x4c80)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 512)*/ mload(0x4820),
                        sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x4ca0)),
                        PRIME),
                      PRIME),
                    /*domains[16]*/ mload(0x5080),
                    PRIME),
                  PRIME)
                mstore(0x50a0, domain)
              }

              // Numerator for constraints: 'poseidon/poseidon/partial_rounds_state1_squaring'.
              // domains[18] = domain14 * domain17.
              mstore(0x50c0,
                     mulmod(/*domains[14]*/ mload(0x5040), /*domains[17]*/ mload(0x50a0), PRIME))

              // Numerator for constraints: 'poseidon/poseidon/partial_round0'.
              // domains[19] = (point^(trace_length / 512) - trace_generator^(61 * trace_length / 64)) * (point^(trace_length / 512) - trace_generator^(63 * trace_length / 64)) * domain16.
              mstore(0x50e0,
                     mulmod(
                       mulmod(
                         addmod(
                           /*point^(trace_length / 512)*/ mload(0x4820),
                           sub(PRIME, /*trace_generator^(61 * trace_length / 64)*/ mload(0x4cc0)),
                           PRIME),
                         addmod(
                           /*point^(trace_length / 512)*/ mload(0x4820),
                           sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4d20)),
                           PRIME),
                         PRIME),
                       /*domains[16]*/ mload(0x5080),
                       PRIME))

              // Numerator for constraints: 'poseidon/poseidon/partial_round1'.
              // domains[20] = (point^(trace_length / 512) - trace_generator^(19 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(21 * trace_length / 32)) * domain15 * domain17.
              mstore(0x5100,
                     mulmod(
                       mulmod(
                         mulmod(
                           addmod(
                             /*point^(trace_length / 512)*/ mload(0x4820),
                             sub(PRIME, /*trace_generator^(19 * trace_length / 32)*/ mload(0x4b40)),
                             PRIME),
                           addmod(
                             /*point^(trace_length / 512)*/ mload(0x4820),
                             sub(PRIME, /*trace_generator^(21 * trace_length / 32)*/ mload(0x4b80)),
                             PRIME),
                           PRIME),
                         /*domains[15]*/ mload(0x5060),
                         PRIME),
                       /*domains[17]*/ mload(0x50a0),
                       PRIME))

              // Numerator for constraints: 'bitwise/step_var_pool_addr'.
              // domains[21] = point^(trace_length / 1024) - trace_generator^(3 * trace_length / 4).
              mstore(0x5120,
                     addmod(
                       /*point^(trace_length / 1024)*/ mload(0x4800),
                       sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x4be0)),
                       PRIME))

              // Denominator for constraints: 'bitwise/x_or_y_addr', 'bitwise/next_var_pool_addr', 'bitwise/or_is_and_plus_xor', 'bitwise/unique_unpacking192', 'bitwise/unique_unpacking193', 'bitwise/unique_unpacking194', 'bitwise/unique_unpacking195'.
              // domains[22] = point^(trace_length / 1024) - 1.
              mstore(0x5140,
                     addmod(/*point^(trace_length / 1024)*/ mload(0x4800), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'bitwise/addition_is_xor_with_and'.
              // domains[23] = (point^(trace_length / 1024) - trace_generator^(trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 16)) * (point^(trace_length / 1024) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 8)) * (point^(trace_length / 1024) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 1024) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(15 * trace_length / 64)) * domain22.
              {
                let domain := mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(trace_length / 64)*/ mload(0x4940)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(trace_length / 32)*/ mload(0x4960)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 1024)*/ mload(0x4800),
                        sub(PRIME, /*trace_generator^(3 * trace_length / 64)*/ mload(0x4980)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 1024)*/ mload(0x4800),
                      sub(PRIME, /*trace_generator^(trace_length / 16)*/ mload(0x49a0)),
                      PRIME),
                    PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 64)*/ mload(0x49c0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(3 * trace_length / 32)*/ mload(0x49e0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 1024)*/ mload(0x4800),
                        sub(PRIME, /*trace_generator^(7 * trace_length / 64)*/ mload(0x4a00)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 1024)*/ mload(0x4800),
                      sub(PRIME, /*trace_generator^(trace_length / 8)*/ mload(0x4a20)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(9 * trace_length / 64)*/ mload(0x4a40)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 32)*/ mload(0x4a60)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 1024)*/ mload(0x4800),
                        sub(PRIME, /*trace_generator^(11 * trace_length / 64)*/ mload(0x4a80)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 1024)*/ mload(0x4800),
                      sub(PRIME, /*trace_generator^(3 * trace_length / 16)*/ mload(0x4aa0)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(13 * trace_length / 64)*/ mload(0x4ac0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 1024)*/ mload(0x4800),
                          sub(PRIME, /*trace_generator^(7 * trace_length / 32)*/ mload(0x4ae0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 1024)*/ mload(0x4800),
                        sub(PRIME, /*trace_generator^(15 * trace_length / 64)*/ mload(0x4b00)),
                        PRIME),
                      PRIME),
                    /*domains[22]*/ mload(0x5140),
                    PRIME),
                  PRIME)
                mstore(0x5160, domain)
              }

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/zeros_tail', 'ec_op/ec_subset_sum/zeros_tail'.
              // Numerator for constraints: 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y', 'ec_op/doubling_q/slope', 'ec_op/doubling_q/x', 'ec_op/doubling_q/y', 'ec_op/ec_subset_sum/booleanity_test', 'ec_op/ec_subset_sum/add_points/slope', 'ec_op/ec_subset_sum/add_points/x', 'ec_op/ec_subset_sum/add_points/y', 'ec_op/ec_subset_sum/add_points/x_diff_inv', 'ec_op/ec_subset_sum/copy_point/x', 'ec_op/ec_subset_sum/copy_point/y'.
              // domains[24] = point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              mstore(0x5180,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x47e0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4d40)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/bit_extraction_end'.
              // domains[25] = point^(trace_length / 16384) - trace_generator^(251 * trace_length / 256).
              mstore(0x51a0,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x47e0),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4d00)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y', 'ecdsa/signature0/r_and_w_nonzero', 'ec_op/p_x_addr', 'ec_op/p_y_addr', 'ec_op/q_x_addr', 'ec_op/q_y_addr', 'ec_op/m_addr', 'ec_op/r_x_addr', 'ec_op/r_y_addr', 'ec_op/get_q_x', 'ec_op/get_q_y', 'ec_op/ec_subset_sum/bit_unpacking/last_one_is_zero', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'ec_op/ec_subset_sum/bit_unpacking/cumulative_bit192', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'ec_op/ec_subset_sum/bit_unpacking/cumulative_bit196', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'ec_op/get_m', 'ec_op/get_p_x', 'ec_op/get_p_y', 'ec_op/set_r_x', 'ec_op/set_r_y'.
              // domains[26] = point^(trace_length / 16384) - 1.
              mstore(0x51c0,
                     addmod(/*point^(trace_length / 16384)*/ mload(0x47e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ec_op/ec_subset_sum/bit_extraction_end'.
              // domains[27] = point^(trace_length / 16384) - trace_generator^(63 * trace_length / 64).
              mstore(0x51e0,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x47e0),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4d20)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/zeros_tail'.
              // Numerator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // domains[28] = point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              mstore(0x5200,
                     addmod(
                       /*point^(trace_length / 32768)*/ mload(0x47c0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4d40)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/bit_extraction_end'.
              // domains[29] = point^(trace_length / 32768) - trace_generator^(251 * trace_length / 256).
              mstore(0x5220,
                     addmod(
                       /*point^(trace_length / 32768)*/ mload(0x47c0),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4d00)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve', 'ecdsa/message_addr', 'ecdsa/pubkey_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // domains[30] = point^(trace_length / 32768) - 1.
              mstore(0x5240,
                     addmod(/*point^(trace_length / 32768)*/ mload(0x47c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_fp', 'final_pc'.
              // Numerator for constraints: 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // domains[31] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x5260,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x4d60)),
                       PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'memory/initial_addr', 'rc16/perm/init0', 'rc16/minimum', 'diluted_check/permutation/init0', 'diluted_check/init', 'diluted_check/first_element', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'bitwise/init_var_pool_addr', 'ec_op/init_addr', 'poseidon/init_input_output_addr'.
              // domains[32] = point - 1.
              mstore(0x5280,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last'.
              // Numerator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // domains[33] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x52a0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x4d80)),
                       PRIME))

              // Denominator for constraints: 'rc16/perm/last', 'rc16/maximum'.
              // Numerator for constraints: 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // domains[34] = point - trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x52c0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4 * (trace_length / 4 - 1))*/ mload(0x4da0)),
                       PRIME))

              // Denominator for constraints: 'diluted_check/permutation/last', 'diluted_check/last'.
              // Numerator for constraints: 'diluted_check/permutation/step0', 'diluted_check/step'.
              // domains[35] = point - trace_generator^(8 * (trace_length / 8 - 1)).
              mstore(0x52e0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(8 * (trace_length / 8 - 1))*/ mload(0x4dc0)),
                       PRIME))

              // Numerator for constraints: 'pedersen/input0_addr', 'poseidon/addr_input_output_step_outter'.
              // domains[36] = point - trace_generator^(512 * (trace_length / 512 - 1)).
              mstore(0x5300,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(512 * (trace_length / 512 - 1))*/ mload(0x4de0)),
                       PRIME))

              // Numerator for constraints: 'rc_builtin/addr_step'.
              // domains[37] = point - trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x5320,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(256 * (trace_length / 256 - 1))*/ mload(0x4e00)),
                       PRIME))

              // Numerator for constraints: 'ecdsa/pubkey_addr'.
              // domains[38] = point - trace_generator^(32768 * (trace_length / 32768 - 1)).
              mstore(0x5340,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(32768 * (trace_length / 32768 - 1))*/ mload(0x4e20)),
                       PRIME))

              // Numerator for constraints: 'bitwise/next_var_pool_addr'.
              // domains[39] = point - trace_generator^(1024 * (trace_length / 1024 - 1)).
              mstore(0x5360,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(1024 * (trace_length / 1024 - 1))*/ mload(0x4e40)),
                       PRIME))

              // Numerator for constraints: 'ec_op/p_x_addr'.
              // domains[40] = point - trace_generator^(16384 * (trace_length / 16384 - 1)).
              mstore(0x5380,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16384 * (trace_length / 16384 - 1))*/ mload(0x4e60)),
                       PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // denominators[0] = domains[0].
              mstore(0x56e0, /*domains[0]*/ mload(0x4e80))

              // denominators[1] = domains[4].
              mstore(0x5700, /*domains[4]*/ mload(0x4f00))

              // denominators[2] = domains[5].
              mstore(0x5720, /*domains[5]*/ mload(0x4f20))

              // denominators[3] = domains[31].
              mstore(0x5740, /*domains[31]*/ mload(0x5260))

              // denominators[4] = domains[32].
              mstore(0x5760, /*domains[32]*/ mload(0x5280))

              // denominators[5] = domains[1].
              mstore(0x5780, /*domains[1]*/ mload(0x4ea0))

              // denominators[6] = domains[33].
              mstore(0x57a0, /*domains[33]*/ mload(0x52a0))

              // denominators[7] = domains[3].
              mstore(0x57c0, /*domains[3]*/ mload(0x4ee0))

              // denominators[8] = domains[2].
              mstore(0x57e0, /*domains[2]*/ mload(0x4ec0))

              // denominators[9] = domains[34].
              mstore(0x5800, /*domains[34]*/ mload(0x52c0))

              // denominators[10] = domains[35].
              mstore(0x5820, /*domains[35]*/ mload(0x52e0))

              // denominators[11] = domains[8].
              mstore(0x5840, /*domains[8]*/ mload(0x4f80))

              // denominators[12] = domains[9].
              mstore(0x5860, /*domains[9]*/ mload(0x4fa0))

              // denominators[13] = domains[10].
              mstore(0x5880, /*domains[10]*/ mload(0x4fc0))

              // denominators[14] = domains[13].
              mstore(0x58a0, /*domains[13]*/ mload(0x5020))

              // denominators[15] = domains[6].
              mstore(0x58c0, /*domains[6]*/ mload(0x4f40))

              // denominators[16] = domains[24].
              mstore(0x58e0, /*domains[24]*/ mload(0x5180))

              // denominators[17] = domains[7].
              mstore(0x5900, /*domains[7]*/ mload(0x4f60))

              // denominators[18] = domains[28].
              mstore(0x5920, /*domains[28]*/ mload(0x5200))

              // denominators[19] = domains[29].
              mstore(0x5940, /*domains[29]*/ mload(0x5220))

              // denominators[20] = domains[25].
              mstore(0x5960, /*domains[25]*/ mload(0x51a0))

              // denominators[21] = domains[30].
              mstore(0x5980, /*domains[30]*/ mload(0x5240))

              // denominators[22] = domains[26].
              mstore(0x59a0, /*domains[26]*/ mload(0x51c0))

              // denominators[23] = domains[22].
              mstore(0x59c0, /*domains[22]*/ mload(0x5140))

              // denominators[24] = domains[23].
              mstore(0x59e0, /*domains[23]*/ mload(0x5160))

              // denominators[25] = domains[27].
              mstore(0x5a00, /*domains[27]*/ mload(0x51e0))

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x340
              let prod := 1
              let partialProductEndPtr := 0x56e0
              for { let partialProductPtr := 0x53a0 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x53a0
              // Compute the inverse of the product.
              let prodInv := expmod(prod, sub(PRIME, 2), PRIME)

              if eq(prodInv, 0) {
                  // Solidity generates reverts with reason that look as follows:
                  // 1. 4 bytes with the constant 0x08c379a0 (== Keccak256(b'Error(string)')[:4]).
                  // 2. 32 bytes offset bytes (always 0x20 as far as i can tell).
                  // 3. 32 bytes with the length of the revert reason.
                  // 4. Revert reason string.

                  mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                  mstore(0x4, 0x20)
                  mstore(0x24, 0x1e)
                  mstore(0x44, "Batch inverse product is zero.")
                  revert(0, 0x62)
              }

              // Compute the inverses.
              // Loop over denominator_invs in reverse order.
              // currentPartialProductPtr is initialized to one past the end.
              let currentPartialProductPtr := 0x56e0
              for { } gt(currentPartialProductPtr, firstPartialProductPtr) { } {
                  currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                  // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                  mstore(currentPartialProductPtr,
                         mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                  // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                  prodInv := mulmod(prodInv,
                                     mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                     PRIME)
              }
            }

            {
              // Compute the result of the composition polynomial.

              {
              // cpu/decode/opcode_rc/bit_0 = column0_row0 - (column0_row1 + column0_row1).
              let val := addmod(
                /*column0_row0*/ mload(0x1ea0),
                sub(
                  PRIME,
                  addmod(/*column0_row1*/ mload(0x1ec0), /*column0_row1*/ mload(0x1ec0), PRIME)),
                PRIME)
              mstore(0x4040, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column0_row2 - (column0_row3 + column0_row3).
              let val := addmod(
                /*column0_row2*/ mload(0x1ee0),
                sub(
                  PRIME,
                  addmod(/*column0_row3*/ mload(0x1f00), /*column0_row3*/ mload(0x1f00), PRIME)),
                PRIME)
              mstore(0x4060, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column0_row4 - (column0_row5 + column0_row5).
              let val := addmod(
                /*column0_row4*/ mload(0x1f20),
                sub(
                  PRIME,
                  addmod(/*column0_row5*/ mload(0x1f40), /*column0_row5*/ mload(0x1f40), PRIME)),
                PRIME)
              mstore(0x4080, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column0_row3 - (column0_row4 + column0_row4).
              let val := addmod(
                /*column0_row3*/ mload(0x1f00),
                sub(
                  PRIME,
                  addmod(/*column0_row4*/ mload(0x1f20), /*column0_row4*/ mload(0x1f20), PRIME)),
                PRIME)
              mstore(0x40a0, val)
              }


              {
              // cpu/decode/flag_op1_base_op0_0 = 1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4060),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x4080),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x40a0),
                    PRIME)),
                PRIME)
              mstore(0x40c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column0_row5 - (column0_row6 + column0_row6).
              let val := addmod(
                /*column0_row5*/ mload(0x1f40),
                sub(
                  PRIME,
                  addmod(/*column0_row6*/ mload(0x1f60), /*column0_row6*/ mload(0x1f60), PRIME)),
                PRIME)
              mstore(0x40e0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column0_row6 - (column0_row7 + column0_row7).
              let val := addmod(
                /*column0_row6*/ mload(0x1f60),
                sub(
                  PRIME,
                  addmod(/*column0_row7*/ mload(0x1f80), /*column0_row7*/ mload(0x1f80), PRIME)),
                PRIME)
              mstore(0x4100, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column0_row9 - (column0_row10 + column0_row10).
              let val := addmod(
                /*column0_row9*/ mload(0x1fc0),
                sub(
                  PRIME,
                  addmod(/*column0_row10*/ mload(0x1fe0), /*column0_row10*/ mload(0x1fe0), PRIME)),
                PRIME)
              mstore(0x4120, val)
              }


              {
              // cpu/decode/flag_res_op1_0 = 1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x40e0),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x4100),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120),
                    PRIME)),
                PRIME)
              mstore(0x4140, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column0_row7 - (column0_row8 + column0_row8).
              let val := addmod(
                /*column0_row7*/ mload(0x1f80),
                sub(
                  PRIME,
                  addmod(/*column0_row8*/ mload(0x1fa0), /*column0_row8*/ mload(0x1fa0), PRIME)),
                PRIME)
              mstore(0x4160, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column0_row8 - (column0_row9 + column0_row9).
              let val := addmod(
                /*column0_row8*/ mload(0x1fa0),
                sub(
                  PRIME,
                  addmod(/*column0_row9*/ mload(0x1fc0), /*column0_row9*/ mload(0x1fc0), PRIME)),
                PRIME)
              mstore(0x4180, val)
              }


              {
              // cpu/decode/flag_pc_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4160),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4180),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120),
                    PRIME)),
                PRIME)
              mstore(0x41a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column0_row12 - (column0_row13 + column0_row13).
              let val := addmod(
                /*column0_row12*/ mload(0x2020),
                sub(
                  PRIME,
                  addmod(/*column0_row13*/ mload(0x2040), /*column0_row13*/ mload(0x2040), PRIME)),
                PRIME)
              mstore(0x41c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column0_row13 - (column0_row14 + column0_row14).
              let val := addmod(
                /*column0_row13*/ mload(0x2040),
                sub(
                  PRIME,
                  addmod(/*column0_row14*/ mload(0x2060), /*column0_row14*/ mload(0x2060), PRIME)),
                PRIME)
              mstore(0x41e0, val)
              }


              {
              // cpu/decode/fp_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x41e0),
                    PRIME)),
                PRIME)
              mstore(0x4200, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column0_row1 - (column0_row2 + column0_row2).
              let val := addmod(
                /*column0_row1*/ mload(0x1ec0),
                sub(
                  PRIME,
                  addmod(/*column0_row2*/ mload(0x1ee0), /*column0_row2*/ mload(0x1ee0), PRIME)),
                PRIME)
              mstore(0x4220, val)
              }


              {
              // npc_reg_0 = column5_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column5_row0*/ mload(0x2320),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4060),
                  PRIME),
                1,
                PRIME)
              mstore(0x4240, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column0_row10 - (column0_row11 + column0_row11).
              let val := addmod(
                /*column0_row10*/ mload(0x1fe0),
                sub(
                  PRIME,
                  addmod(/*column0_row11*/ mload(0x2000), /*column0_row11*/ mload(0x2000), PRIME)),
                PRIME)
              mstore(0x4260, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column0_row11 - (column0_row12 + column0_row12).
              let val := addmod(
                /*column0_row11*/ mload(0x2000),
                sub(
                  PRIME,
                  addmod(/*column0_row12*/ mload(0x2020), /*column0_row12*/ mload(0x2020), PRIME)),
                PRIME)
              mstore(0x4280, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column0_row14 - (column0_row15 + column0_row15).
              let val := addmod(
                /*column0_row14*/ mload(0x2060),
                sub(
                  PRIME,
                  addmod(/*column0_row15*/ mload(0x2080), /*column0_row15*/ mload(0x2080), PRIME)),
                PRIME)
              mstore(0x42a0, val)
              }


              {
              // memory/address_diff_0 = column6_row2 - column6_row0.
              let val := addmod(/*column6_row2*/ mload(0x2ae0), sub(PRIME, /*column6_row0*/ mload(0x2aa0)), PRIME)
              mstore(0x42c0, val)
              }


              {
              // rc16/diff_0 = column7_row6 - column7_row2.
              let val := addmod(/*column7_row6*/ mload(0x2be0), sub(PRIME, /*column7_row2*/ mload(0x2b60)), PRIME)
              mstore(0x42e0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column3_row0 - (column3_row1 + column3_row1).
              let val := addmod(
                /*column3_row0*/ mload(0x21c0),
                sub(
                  PRIME,
                  addmod(/*column3_row1*/ mload(0x21e0), /*column3_row1*/ mload(0x21e0), PRIME)),
                PRIME)
              mstore(0x4300, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300)),
                PRIME)
              mstore(0x4320, val)
              }


              {
              // rc_builtin/value0_0 = column7_row12.
              let val := /*column7_row12*/ mload(0x2c80)
              mstore(0x4340, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column7_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x4340),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row44*/ mload(0x2d80),
                PRIME)
              mstore(0x4360, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column7_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x4360),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row76*/ mload(0x2de0),
                PRIME)
              mstore(0x4380, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column7_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x4380),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row108*/ mload(0x2e40),
                PRIME)
              mstore(0x43a0, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column7_row140.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x43a0),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row140*/ mload(0x2ea0),
                PRIME)
              mstore(0x43c0, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column7_row172.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x43c0),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row172*/ mload(0x2f00),
                PRIME)
              mstore(0x43e0, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column7_row204.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x43e0),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row204*/ mload(0x2f60),
                PRIME)
              mstore(0x4400, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column7_row236.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x4400),
                  /*offset_size*/ mload(0x140),
                  PRIME),
                /*column7_row236*/ mload(0x2fc0),
                PRIME)
              mstore(0x4420, val)
              }


              {
              // ecdsa/signature0/doubling_key/x_squared = column8_row1 * column8_row1.
              let val := mulmod(/*column8_row1*/ mload(0x3240), /*column8_row1*/ mload(0x3240), PRIME)
              mstore(0x4440, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_0 = column8_row59 - (column8_row187 + column8_row187).
              let val := addmod(
                /*column8_row59*/ mload(0x36e0),
                sub(
                  PRIME,
                  addmod(/*column8_row187*/ mload(0x3940), /*column8_row187*/ mload(0x3940), PRIME)),
                PRIME)
              mstore(0x4460, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_generator__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460)),
                PRIME)
              mstore(0x4480, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_0 = column8_row9 - (column8_row73 + column8_row73).
              let val := addmod(
                /*column8_row9*/ mload(0x3340),
                sub(
                  PRIME,
                  addmod(/*column8_row73*/ mload(0x3780), /*column8_row73*/ mload(0x3780), PRIME)),
                PRIME)
              mstore(0x44a0, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_key__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0)),
                PRIME)
              mstore(0x44c0, val)
              }


              {
              // bitwise/sum_var_0_0 = column7_row1 + column7_row17 * 2 + column7_row33 * 4 + column7_row49 * 8 + column7_row65 * 18446744073709551616 + column7_row81 * 36893488147419103232 + column7_row97 * 73786976294838206464 + column7_row113 * 147573952589676412928.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            /*column7_row1*/ mload(0x2b40),
                            mulmod(/*column7_row17*/ mload(0x2ce0), 2, PRIME),
                            PRIME),
                          mulmod(/*column7_row33*/ mload(0x2d60), 4, PRIME),
                          PRIME),
                        mulmod(/*column7_row49*/ mload(0x2da0), 8, PRIME),
                        PRIME),
                      mulmod(/*column7_row65*/ mload(0x2dc0), 18446744073709551616, PRIME),
                      PRIME),
                    mulmod(/*column7_row81*/ mload(0x2e00), 36893488147419103232, PRIME),
                    PRIME),
                  mulmod(/*column7_row97*/ mload(0x2e20), 73786976294838206464, PRIME),
                  PRIME),
                mulmod(/*column7_row113*/ mload(0x2e60), 147573952589676412928, PRIME),
                PRIME)
              mstore(0x44e0, val)
              }


              {
              // bitwise/sum_var_8_0 = column7_row129 * 340282366920938463463374607431768211456 + column7_row145 * 680564733841876926926749214863536422912 + column7_row161 * 1361129467683753853853498429727072845824 + column7_row177 * 2722258935367507707706996859454145691648 + column7_row193 * 6277101735386680763835789423207666416102355444464034512896 + column7_row209 * 12554203470773361527671578846415332832204710888928069025792 + column7_row225 * 25108406941546723055343157692830665664409421777856138051584 + column7_row241 * 50216813883093446110686315385661331328818843555712276103168.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            mulmod(/*column7_row129*/ mload(0x2e80), 340282366920938463463374607431768211456, PRIME),
                            mulmod(/*column7_row145*/ mload(0x2ec0), 680564733841876926926749214863536422912, PRIME),
                            PRIME),
                          mulmod(/*column7_row161*/ mload(0x2ee0), 1361129467683753853853498429727072845824, PRIME),
                          PRIME),
                        mulmod(/*column7_row177*/ mload(0x2f20), 2722258935367507707706996859454145691648, PRIME),
                        PRIME),
                      mulmod(
                        /*column7_row193*/ mload(0x2f40),
                        6277101735386680763835789423207666416102355444464034512896,
                        PRIME),
                      PRIME),
                    mulmod(
                      /*column7_row209*/ mload(0x2f80),
                      12554203470773361527671578846415332832204710888928069025792,
                      PRIME),
                    PRIME),
                  mulmod(
                    /*column7_row225*/ mload(0x2fa0),
                    25108406941546723055343157692830665664409421777856138051584,
                    PRIME),
                  PRIME),
                mulmod(
                  /*column7_row241*/ mload(0x2fe0),
                  50216813883093446110686315385661331328818843555712276103168,
                  PRIME),
                PRIME)
              mstore(0x4500, val)
              }


              {
              // ec_op/doubling_q/x_squared_0 = column8_row41 * column8_row41.
              let val := mulmod(/*column8_row41*/ mload(0x35c0), /*column8_row41*/ mload(0x35c0), PRIME)
              mstore(0x4520, val)
              }


              {
              // ec_op/ec_subset_sum/bit_0 = column8_row21 - (column8_row85 + column8_row85).
              let val := addmod(
                /*column8_row21*/ mload(0x3460),
                sub(
                  PRIME,
                  addmod(/*column8_row85*/ mload(0x37e0), /*column8_row85*/ mload(0x37e0), PRIME)),
                PRIME)
              mstore(0x4540, val)
              }


              {
              // ec_op/ec_subset_sum/bit_neg_0 = 1 - ec_op__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540)),
                PRIME)
              mstore(0x4560, val)
              }


              {
              // poseidon/poseidon/full_rounds_state0_cubed_0 = column8_row53 * column8_row29.
              let val := mulmod(/*column8_row53*/ mload(0x3680), /*column8_row29*/ mload(0x3500), PRIME)
              mstore(0x4580, val)
              }


              {
              // poseidon/poseidon/full_rounds_state1_cubed_0 = column8_row13 * column8_row61.
              let val := mulmod(/*column8_row13*/ mload(0x33c0), /*column8_row61*/ mload(0x3700), PRIME)
              mstore(0x45a0, val)
              }


              {
              // poseidon/poseidon/full_rounds_state2_cubed_0 = column8_row45 * column8_row3.
              let val := mulmod(/*column8_row45*/ mload(0x3600), /*column8_row3*/ mload(0x3280), PRIME)
              mstore(0x45c0, val)
              }


              {
              // poseidon/poseidon/full_rounds_state0_cubed_7 = column8_row501 * column8_row477.
              let val := mulmod(/*column8_row501*/ mload(0x3be0), /*column8_row477*/ mload(0x3ba0), PRIME)
              mstore(0x45e0, val)
              }


              {
              // poseidon/poseidon/full_rounds_state1_cubed_7 = column8_row461 * column8_row509.
              let val := mulmod(/*column8_row461*/ mload(0x3b80), /*column8_row509*/ mload(0x3c00), PRIME)
              mstore(0x4600, val)
              }


              {
              // poseidon/poseidon/full_rounds_state2_cubed_7 = column8_row493 * column8_row451.
              let val := mulmod(/*column8_row493*/ mload(0x3bc0), /*column8_row451*/ mload(0x3b60), PRIME)
              mstore(0x4620, val)
              }


              {
              // poseidon/poseidon/full_rounds_state0_cubed_3 = column8_row245 * column8_row221.
              let val := mulmod(/*column8_row245*/ mload(0x3a00), /*column8_row221*/ mload(0x39c0), PRIME)
              mstore(0x4640, val)
              }


              {
              // poseidon/poseidon/full_rounds_state1_cubed_3 = column8_row205 * column8_row253.
              let val := mulmod(/*column8_row205*/ mload(0x3980), /*column8_row253*/ mload(0x3a20), PRIME)
              mstore(0x4660, val)
              }


              {
              // poseidon/poseidon/full_rounds_state2_cubed_3 = column8_row237 * column8_row195.
              let val := mulmod(/*column8_row237*/ mload(0x39e0), /*column8_row195*/ mload(0x3960), PRIME)
              mstore(0x4680, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state0_cubed_0 = column7_row3 * column7_row7.
              let val := mulmod(/*column7_row3*/ mload(0x2b80), /*column7_row7*/ mload(0x2c00), PRIME)
              mstore(0x46a0, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state0_cubed_1 = column7_row11 * column7_row15.
              let val := mulmod(/*column7_row11*/ mload(0x2c60), /*column7_row15*/ mload(0x2cc0), PRIME)
              mstore(0x46c0, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state0_cubed_2 = column7_row19 * column7_row23.
              let val := mulmod(/*column7_row19*/ mload(0x2d00), /*column7_row23*/ mload(0x2d20), PRIME)
              mstore(0x46e0, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_0 = column8_row6 * column8_row14.
              let val := mulmod(/*column8_row6*/ mload(0x32e0), /*column8_row14*/ mload(0x33e0), PRIME)
              mstore(0x4700, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_1 = column8_row22 * column8_row30.
              let val := mulmod(/*column8_row22*/ mload(0x3480), /*column8_row30*/ mload(0x3520), PRIME)
              mstore(0x4720, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_2 = column8_row38 * column8_row46.
              let val := mulmod(/*column8_row38*/ mload(0x35a0), /*column8_row46*/ mload(0x3620), PRIME)
              mstore(0x4740, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_19 = column8_row310 * column8_row318.
              let val := mulmod(/*column8_row310*/ mload(0x3aa0), /*column8_row318*/ mload(0x3ac0), PRIME)
              mstore(0x4760, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_20 = column8_row326 * column8_row334.
              let val := mulmod(/*column8_row326*/ mload(0x3ae0), /*column8_row334*/ mload(0x3b00), PRIME)
              mstore(0x4780, val)
              }


              {
              // poseidon/poseidon/partial_rounds_state1_cubed_21 = column8_row342 * column8_row350.
              let val := mulmod(/*column8_row342*/ mload(0x3b20), /*column8_row350*/ mload(0x3b40), PRIME)
              mstore(0x47a0, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= domains[4].
              val := mulmod(val, /*domains[4]*/ mload(0x4f00), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[0].
              res := addmod(res,
                            mulmod(val, /*coefficients[0]*/ mload(0x640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/zero: column0_row0.
              let val := /*column0_row0*/ mload(0x1ea0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, /*denominator_invs[1]*/ mload(0x53c0), PRIME)

              // res += val * coefficients[1].
              res := addmod(res,
                            mulmod(val, /*coefficients[1]*/ mload(0x660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column5_row1 - (((column0_row0 * offset_size + column7_row4) * offset_size + column7_row8) * offset_size + column7_row0).
              let val := addmod(
                /*column5_row1*/ mload(0x2340),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column0_row0*/ mload(0x1ea0), /*offset_size*/ mload(0x140), PRIME),
                            /*column7_row4*/ mload(0x2ba0),
                            PRIME),
                          /*offset_size*/ mload(0x140),
                          PRIME),
                        /*column7_row8*/ mload(0x2c20),
                        PRIME),
                      /*offset_size*/ mload(0x140),
                      PRIME),
                    /*column7_row0*/ mload(0x2b20),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[2].
              res := addmod(res,
                            mulmod(val, /*coefficients[2]*/ mload(0x680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_op1_base_op0_bit: cpu__decode__flag_op1_base_op0_0 * cpu__decode__flag_op1_base_op0_0 - cpu__decode__flag_op1_base_op0_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x40c0),
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x40c0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x40c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[3].
              res := addmod(res,
                            mulmod(val, /*coefficients[3]*/ mload(0x6a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_res_op1_bit: cpu__decode__flag_res_op1_0 * cpu__decode__flag_res_op1_0 - cpu__decode__flag_res_op1_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4140),
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4140),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4140)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[4].
              res := addmod(res,
                            mulmod(val, /*coefficients[4]*/ mload(0x6c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_pc_update_regular_bit: cpu__decode__flag_pc_update_regular_0 * cpu__decode__flag_pc_update_regular_0 - cpu__decode__flag_pc_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x41a0),
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x41a0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x41a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[5].
              res := addmod(res,
                            mulmod(val, /*coefficients[5]*/ mload(0x6e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/fp_update_regular_bit: cpu__decode__fp_update_regular_0 * cpu__decode__fp_update_regular_0 - cpu__decode__fp_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x4200),
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x4200),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x4200)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[6].
              res := addmod(res,
                            mulmod(val, /*coefficients[6]*/ mload(0x700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column5_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column8_row8 + (1 - cpu__decode__opcode_rc__bit_0) * column8_row0 + column7_row0).
              let val := addmod(
                addmod(/*column5_row8*/ mload(0x2420), /*half_offset_size*/ mload(0x160), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040),
                        /*column8_row8*/ mload(0x3320),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040)),
                          PRIME),
                        /*column8_row0*/ mload(0x3220),
                        PRIME),
                      PRIME),
                    /*column7_row0*/ mload(0x2b20),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[7].
              res := addmod(res,
                            mulmod(val, /*coefficients[7]*/ mload(0x720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column5_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column8_row8 + (1 - cpu__decode__opcode_rc__bit_1) * column8_row0 + column7_row8).
              let val := addmod(
                addmod(/*column5_row4*/ mload(0x23a0), /*half_offset_size*/ mload(0x160), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x4220),
                        /*column8_row8*/ mload(0x3320),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x4220)),
                          PRIME),
                        /*column8_row0*/ mload(0x3220),
                        PRIME),
                      PRIME),
                    /*column7_row8*/ mload(0x2c20),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[8].
              res := addmod(res,
                            mulmod(val, /*coefficients[8]*/ mload(0x740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column5_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column5_row0 + cpu__decode__opcode_rc__bit_4 * column8_row0 + cpu__decode__opcode_rc__bit_3 * column8_row8 + cpu__decode__flag_op1_base_op0_0 * column5_row5 + column7_row4).
              let val := addmod(
                addmod(/*column5_row12*/ mload(0x2460), /*half_offset_size*/ mload(0x160), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4060),
                            /*column5_row0*/ mload(0x2320),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x4080),
                            /*column8_row0*/ mload(0x3220),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x40a0),
                          /*column8_row8*/ mload(0x3320),
                          PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x40c0),
                        /*column5_row5*/ mload(0x23c0),
                        PRIME),
                      PRIME),
                    /*column7_row4*/ mload(0x2ba0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[9].
              res := addmod(res,
                            mulmod(val, /*coefficients[9]*/ mload(0x760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column8_row4 - column5_row5 * column5_row13.
              let val := addmod(
                /*column8_row4*/ mload(0x32a0),
                sub(
                  PRIME,
                  mulmod(/*column5_row5*/ mload(0x23c0), /*column5_row13*/ mload(0x2480), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[10].
              res := addmod(res,
                            mulmod(val, /*coefficients[10]*/ mload(0x780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column8_row12 - (cpu__decode__opcode_rc__bit_5 * (column5_row5 + column5_row13) + cpu__decode__opcode_rc__bit_6 * column8_row4 + cpu__decode__flag_res_op1_0 * column5_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120)),
                    PRIME),
                  /*column8_row12*/ mload(0x33a0),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x40e0),
                        addmod(/*column5_row5*/ mload(0x23c0), /*column5_row13*/ mload(0x2480), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x4100),
                        /*column8_row4*/ mload(0x32a0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4140),
                      /*column5_row13*/ mload(0x2480),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[11].
              res := addmod(res,
                            mulmod(val, /*coefficients[11]*/ mload(0x7a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column8_row2 - cpu__decode__opcode_rc__bit_9 * column5_row9.
              let val := addmod(
                /*column8_row2*/ mload(0x3260),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120),
                    /*column5_row9*/ mload(0x2440),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[12].
              res := addmod(res,
                            mulmod(val, /*coefficients[12]*/ mload(0x7c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column8_row10 - column8_row2 * column8_row12.
              let val := addmod(
                /*column8_row10*/ mload(0x3360),
                sub(
                  PRIME,
                  mulmod(/*column8_row2*/ mload(0x3260), /*column8_row12*/ mload(0x33a0), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[13].
              res := addmod(res,
                            mulmod(val, /*coefficients[13]*/ mload(0x7e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column5_row16 + column8_row2 * (column5_row16 - (column5_row0 + column5_row13)) - (cpu__decode__flag_pc_update_regular_0 * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column8_row12 + cpu__decode__opcode_rc__bit_8 * (column5_row0 + column8_row12)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120)),
                      PRIME),
                    /*column5_row16*/ mload(0x24a0),
                    PRIME),
                  mulmod(
                    /*column8_row2*/ mload(0x3260),
                    addmod(
                      /*column5_row16*/ mload(0x24a0),
                      sub(
                        PRIME,
                        addmod(/*column5_row0*/ mload(0x2320), /*column5_row13*/ mload(0x2480), PRIME)),
                      PRIME),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x41a0),
                        /*intermediate_value/npc_reg_0*/ mload(0x4240),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4160),
                        /*column8_row12*/ mload(0x33a0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4180),
                      addmod(/*column5_row0*/ mload(0x2320), /*column8_row12*/ mload(0x33a0), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[14].
              res := addmod(res,
                            mulmod(val, /*coefficients[14]*/ mload(0x800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column8_row10 - cpu__decode__opcode_rc__bit_9) * (column5_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column8_row10*/ mload(0x3360),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4120)),
                  PRIME),
                addmod(
                  /*column5_row16*/ mload(0x24a0),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x4240)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[15].
              res := addmod(res,
                            mulmod(val, /*coefficients[15]*/ mload(0x820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column8_row16 - (column8_row0 + cpu__decode__opcode_rc__bit_10 * column8_row12 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column8_row16*/ mload(0x3400),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column8_row0*/ mload(0x3220),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x4260),
                          /*column8_row12*/ mload(0x33a0),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x4280),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[16].
              res := addmod(res,
                            mulmod(val, /*coefficients[16]*/ mload(0x840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column8_row24 - (cpu__decode__fp_update_regular_0 * column8_row8 + cpu__decode__opcode_rc__bit_13 * column5_row9 + cpu__decode__opcode_rc__bit_12 * (column8_row0 + 2)).
              let val := addmod(
                /*column8_row24*/ mload(0x34a0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x4200),
                        /*column8_row8*/ mload(0x3320),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x41e0),
                        /*column5_row9*/ mload(0x2440),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                      addmod(/*column8_row0*/ mload(0x3220), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[31].
              val := mulmod(val, /*domains[31]*/ mload(0x5260), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[17].
              res := addmod(res,
                            mulmod(val, /*coefficients[17]*/ mload(0x860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column5_row9 - column8_row8).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                addmod(/*column5_row9*/ mload(0x2440), sub(PRIME, /*column8_row8*/ mload(0x3320)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[18].
              res := addmod(res,
                            mulmod(val, /*coefficients[18]*/ mload(0x880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column5_row5 - (column5_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                addmod(
                  /*column5_row5*/ mload(0x23c0),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column5_row0*/ mload(0x2320),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4060),
                        PRIME),
                      1,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[19].
              res := addmod(res,
                            mulmod(val, /*coefficients[19]*/ mload(0x8a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off0: cpu__decode__opcode_rc__bit_12 * (column7_row0 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                addmod(
                  /*column7_row0*/ mload(0x2b20),
                  sub(PRIME, /*half_offset_size*/ mload(0x160)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[20].
              res := addmod(res,
                            mulmod(val, /*coefficients[20]*/ mload(0x8c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off1: cpu__decode__opcode_rc__bit_12 * (column7_row8 - (half_offset_size + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                addmod(
                  /*column7_row8*/ mload(0x2c20),
                  sub(PRIME, addmod(/*half_offset_size*/ mload(0x160), 1, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[21].
              res := addmod(res,
                            mulmod(val, /*coefficients[21]*/ mload(0x8e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/flags: cpu__decode__opcode_rc__bit_12 * (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_12 + 1 + 1 - (cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_1 + 4)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x41c0),
                        PRIME),
                      1,
                      PRIME),
                    1,
                    PRIME),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x4220),
                        PRIME),
                      4,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[22].
              res := addmod(res,
                            mulmod(val, /*coefficients[22]*/ mload(0x900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off0: cpu__decode__opcode_rc__bit_13 * (column7_row0 + 2 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x41e0),
                addmod(
                  addmod(/*column7_row0*/ mload(0x2b20), 2, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0x160)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[23].
              res := addmod(res,
                            mulmod(val, /*coefficients[23]*/ mload(0x920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off2: cpu__decode__opcode_rc__bit_13 * (column7_row4 + 1 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x41e0),
                addmod(
                  addmod(/*column7_row4*/ mload(0x2ba0), 1, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0x160)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[24].
              res := addmod(res,
                            mulmod(val, /*coefficients[24]*/ mload(0x940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/flags: cpu__decode__opcode_rc__bit_13 * (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_3 + cpu__decode__flag_res_op1_0 - 4).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x41e0),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4160),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4040),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x40a0),
                      PRIME),
                    /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4140),
                    PRIME),
                  sub(PRIME, 4),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[25].
              res := addmod(res,
                            mulmod(val, /*coefficients[25]*/ mload(0x960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column5_row9 - column8_row12).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x42a0),
                addmod(/*column5_row9*/ mload(0x2440), sub(PRIME, /*column8_row12*/ mload(0x33a0)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[26].
              res := addmod(res,
                            mulmod(val, /*coefficients[26]*/ mload(0x980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_ap: column8_row0 - initial_ap.
              let val := addmod(/*column8_row0*/ mload(0x3220), sub(PRIME, /*initial_ap*/ mload(0x180)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[27].
              res := addmod(res,
                            mulmod(val, /*coefficients[27]*/ mload(0x9a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_fp: column8_row8 - initial_ap.
              let val := addmod(/*column8_row8*/ mload(0x3320), sub(PRIME, /*initial_ap*/ mload(0x180)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[28].
              res := addmod(res,
                            mulmod(val, /*coefficients[28]*/ mload(0x9c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_pc: column5_row0 - initial_pc.
              let val := addmod(/*column5_row0*/ mload(0x2320), sub(PRIME, /*initial_pc*/ mload(0x1a0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[29].
              res := addmod(res,
                            mulmod(val, /*coefficients[29]*/ mload(0x9e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_ap: column8_row0 - final_ap.
              let val := addmod(/*column8_row0*/ mload(0x3220), sub(PRIME, /*final_ap*/ mload(0x1c0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5400), PRIME)

              // res += val * coefficients[30].
              res := addmod(res,
                            mulmod(val, /*coefficients[30]*/ mload(0xa00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_fp: column8_row8 - initial_ap.
              let val := addmod(/*column8_row8*/ mload(0x3320), sub(PRIME, /*initial_ap*/ mload(0x180)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5400), PRIME)

              // res += val * coefficients[31].
              res := addmod(res,
                            mulmod(val, /*coefficients[31]*/ mload(0xa20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_pc: column5_row0 - final_pc.
              let val := addmod(/*column5_row0*/ mload(0x2320), sub(PRIME, /*final_pc*/ mload(0x1e0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5400), PRIME)

              // res += val * coefficients[32].
              res := addmod(res,
                            mulmod(val, /*coefficients[32]*/ mload(0xa40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column6_row0 + memory/multi_column_perm/hash_interaction_elm0 * column6_row1)) * column9_inter1_row0 + column5_row0 + memory/multi_column_perm/hash_interaction_elm0 * column5_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x200),
                        sub(
                          PRIME,
                          addmod(
                            /*column6_row0*/ mload(0x2aa0),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x220),
                              /*column6_row1*/ mload(0x2ac0),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column9_inter1_row0*/ mload(0x3f40),
                      PRIME),
                    /*column5_row0*/ mload(0x2320),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x220),
                    /*column5_row1*/ mload(0x2340),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x200)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[33].
              res := addmod(res,
                            mulmod(val, /*coefficients[33]*/ mload(0xa60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column6_row2 + memory/multi_column_perm/hash_interaction_elm0 * column6_row3)) * column9_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column5_row2 + memory/multi_column_perm/hash_interaction_elm0 * column5_row3)) * column9_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x200),
                    sub(
                      PRIME,
                      addmod(
                        /*column6_row2*/ mload(0x2ae0),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x220),
                          /*column6_row3*/ mload(0x2b00),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column9_inter1_row2*/ mload(0x3f80),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x200),
                      sub(
                        PRIME,
                        addmod(
                          /*column5_row2*/ mload(0x2360),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x220),
                            /*column5_row3*/ mload(0x2380),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column9_inter1_row0*/ mload(0x3f40),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[33].
              val := mulmod(val, /*domains[33]*/ mload(0x52a0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x5440), PRIME)

              // res += val * coefficients[34].
              res := addmod(res,
                            mulmod(val, /*coefficients[34]*/ mload(0xa80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column9_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row0*/ mload(0x3f40),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, /*denominator_invs[6]*/ mload(0x5460), PRIME)

              // res += val * coefficients[35].
              res := addmod(res,
                            mulmod(val, /*coefficients[35]*/ mload(0xaa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x42c0),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x42c0),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x42c0)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[33].
              val := mulmod(val, /*domains[33]*/ mload(0x52a0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x5440), PRIME)

              // res += val * coefficients[36].
              res := addmod(res,
                            mulmod(val, /*coefficients[36]*/ mload(0xac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column6_row1 - column6_row3).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x42c0), sub(PRIME, 1), PRIME),
                addmod(/*column6_row1*/ mload(0x2ac0), sub(PRIME, /*column6_row3*/ mload(0x2b00)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[33].
              val := mulmod(val, /*domains[33]*/ mload(0x52a0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x5440), PRIME)

              // res += val * coefficients[37].
              res := addmod(res,
                            mulmod(val, /*coefficients[37]*/ mload(0xae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/initial_addr: column6_row0 - 1.
              let val := addmod(/*column6_row0*/ mload(0x2aa0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[38].
              res := addmod(res,
                            mulmod(val, /*coefficients[38]*/ mload(0xb00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column5_row2.
              let val := /*column5_row2*/ mload(0x2360)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[39].
              res := addmod(res,
                            mulmod(val, /*coefficients[39]*/ mload(0xb20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column5_row3.
              let val := /*column5_row3*/ mload(0x2380)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[40].
              res := addmod(res,
                            mulmod(val, /*coefficients[40]*/ mload(0xb40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column7_row2) * column9_inter1_row1 + column7_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x260),
                      sub(PRIME, /*column7_row2*/ mload(0x2b60)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x3f60),
                    PRIME),
                  /*column7_row0*/ mload(0x2b20),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[41].
              res := addmod(res,
                            mulmod(val, /*coefficients[41]*/ mload(0xb60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column7_row6) * column9_inter1_row5 - (rc16/perm/interaction_elm - column7_row4) * column9_inter1_row1.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x260),
                    sub(PRIME, /*column7_row6*/ mload(0x2be0)),
                    PRIME),
                  /*column9_inter1_row5*/ mload(0x3fc0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x260),
                      sub(PRIME, /*column7_row4*/ mload(0x2ba0)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x3f60),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= domains[34].
              val := mulmod(val, /*domains[34]*/ mload(0x52c0), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[42].
              res := addmod(res,
                            mulmod(val, /*coefficients[42]*/ mload(0xb80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column9_inter1_row1 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row1*/ mload(0x3f60),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[43].
              res := addmod(res,
                            mulmod(val, /*coefficients[43]*/ mload(0xba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x42e0),
                  /*intermediate_value/rc16/diff_0*/ mload(0x42e0),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x42e0)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= domains[34].
              val := mulmod(val, /*domains[34]*/ mload(0x52c0), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[44].
              res := addmod(res,
                            mulmod(val, /*coefficients[44]*/ mload(0xbc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column7_row2 - rc_min.
              let val := addmod(/*column7_row2*/ mload(0x2b60), sub(PRIME, /*rc_min*/ mload(0x2a0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[45].
              res := addmod(res,
                            mulmod(val, /*coefficients[45]*/ mload(0xbe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column7_row2 - rc_max.
              let val := addmod(/*column7_row2*/ mload(0x2b60), sub(PRIME, /*rc_max*/ mload(0x2c0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[46].
              res := addmod(res,
                            mulmod(val, /*coefficients[46]*/ mload(0xc00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/init0: (diluted_check/permutation/interaction_elm - column7_row5) * column9_inter1_row7 + column7_row1 - diluted_check/permutation/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x2e0),
                      sub(PRIME, /*column7_row5*/ mload(0x2bc0)),
                      PRIME),
                    /*column9_inter1_row7*/ mload(0x3fe0),
                    PRIME),
                  /*column7_row1*/ mload(0x2b40),
                  PRIME),
                sub(PRIME, /*diluted_check/permutation/interaction_elm*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[47].
              res := addmod(res,
                            mulmod(val, /*coefficients[47]*/ mload(0xc20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/step0: (diluted_check/permutation/interaction_elm - column7_row13) * column9_inter1_row15 - (diluted_check/permutation/interaction_elm - column7_row9) * column9_inter1_row7.
              let val := addmod(
                mulmod(
                  addmod(
                    /*diluted_check/permutation/interaction_elm*/ mload(0x2e0),
                    sub(PRIME, /*column7_row13*/ mload(0x2ca0)),
                    PRIME),
                  /*column9_inter1_row15*/ mload(0x4020),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x2e0),
                      sub(PRIME, /*column7_row9*/ mload(0x2c40)),
                      PRIME),
                    /*column9_inter1_row7*/ mload(0x3fe0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(8 * (trace_length / 8 - 1)).
              // val *= domains[35].
              val := mulmod(val, /*domains[35]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[48].
              res := addmod(res,
                            mulmod(val, /*coefficients[48]*/ mload(0xc40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/last: column9_inter1_row7 - diluted_check/permutation/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row7*/ mload(0x3fe0),
                sub(PRIME, /*diluted_check/permutation/public_memory_prod*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(8 * (trace_length / 8 - 1)).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x54e0), PRIME)

              // res += val * coefficients[49].
              res := addmod(res,
                            mulmod(val, /*coefficients[49]*/ mload(0xc60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/init: column9_inter1_row3 - 1.
              let val := addmod(/*column9_inter1_row3*/ mload(0x3fa0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[50].
              res := addmod(res,
                            mulmod(val, /*coefficients[50]*/ mload(0xc80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/first_element: column7_row5 - diluted_check/first_elm.
              let val := addmod(
                /*column7_row5*/ mload(0x2bc0),
                sub(PRIME, /*diluted_check/first_elm*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[51].
              res := addmod(res,
                            mulmod(val, /*coefficients[51]*/ mload(0xca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/step: column9_inter1_row11 - (column9_inter1_row3 * (1 + diluted_check/interaction_z * (column7_row13 - column7_row5)) + diluted_check/interaction_alpha * (column7_row13 - column7_row5) * (column7_row13 - column7_row5)).
              let val := addmod(
                /*column9_inter1_row11*/ mload(0x4000),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      /*column9_inter1_row3*/ mload(0x3fa0),
                      addmod(
                        1,
                        mulmod(
                          /*diluted_check/interaction_z*/ mload(0x340),
                          addmod(/*column7_row13*/ mload(0x2ca0), sub(PRIME, /*column7_row5*/ mload(0x2bc0)), PRIME),
                          PRIME),
                        PRIME),
                      PRIME),
                    mulmod(
                      mulmod(
                        /*diluted_check/interaction_alpha*/ mload(0x360),
                        addmod(/*column7_row13*/ mload(0x2ca0), sub(PRIME, /*column7_row5*/ mload(0x2bc0)), PRIME),
                        PRIME),
                      addmod(/*column7_row13*/ mload(0x2ca0), sub(PRIME, /*column7_row5*/ mload(0x2bc0)), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(8 * (trace_length / 8 - 1)).
              // val *= domains[35].
              val := mulmod(val, /*domains[35]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[52].
              res := addmod(res,
                            mulmod(val, /*coefficients[52]*/ mload(0xcc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/last: column9_inter1_row3 - diluted_check/final_cum_val.
              let val := addmod(
                /*column9_inter1_row3*/ mload(0x3fa0),
                sub(PRIME, /*diluted_check/final_cum_val*/ mload(0x380)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(8 * (trace_length / 8 - 1)).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x54e0), PRIME)

              // res += val * coefficients[53].
              res := addmod(res,
                            mulmod(val, /*coefficients[53]*/ mload(0xce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero: column8_row71 * (column3_row0 - (column3_row1 + column3_row1)).
              let val := mulmod(
                /*column8_row71*/ mload(0x3760),
                addmod(
                  /*column3_row0*/ mload(0x21c0),
                  sub(
                    PRIME,
                    addmod(/*column3_row1*/ mload(0x21e0), /*column3_row1*/ mload(0x21e0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[54].
              res := addmod(res,
                            mulmod(val, /*coefficients[54]*/ mload(0xd00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column8_row71 * (column3_row1 - 3138550867693340381917894711603833208051177722232017256448 * column3_row192).
              let val := mulmod(
                /*column8_row71*/ mload(0x3760),
                addmod(
                  /*column3_row1*/ mload(0x21e0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column3_row192*/ mload(0x2200),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[55].
              res := addmod(res,
                            mulmod(val, /*coefficients[55]*/ mload(0xd20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192: column8_row71 - column4_row255 * (column3_row192 - (column3_row193 + column3_row193)).
              let val := addmod(
                /*column8_row71*/ mload(0x3760),
                sub(
                  PRIME,
                  mulmod(
                    /*column4_row255*/ mload(0x2300),
                    addmod(
                      /*column3_row192*/ mload(0x2200),
                      sub(
                        PRIME,
                        addmod(/*column3_row193*/ mload(0x2220), /*column3_row193*/ mload(0x2220), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[56].
              res := addmod(res,
                            mulmod(val, /*coefficients[56]*/ mload(0xd40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column4_row255 * (column3_row193 - 8 * column3_row196).
              let val := mulmod(
                /*column4_row255*/ mload(0x2300),
                addmod(
                  /*column3_row193*/ mload(0x2220),
                  sub(PRIME, mulmod(8, /*column3_row196*/ mload(0x2240), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[57].
              res := addmod(res,
                            mulmod(val, /*coefficients[57]*/ mload(0xd60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196: column4_row255 - (column3_row251 - (column3_row252 + column3_row252)) * (column3_row196 - (column3_row197 + column3_row197)).
              let val := addmod(
                /*column4_row255*/ mload(0x2300),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column3_row251*/ mload(0x2280),
                      sub(
                        PRIME,
                        addmod(/*column3_row252*/ mload(0x22a0), /*column3_row252*/ mload(0x22a0), PRIME)),
                      PRIME),
                    addmod(
                      /*column3_row196*/ mload(0x2240),
                      sub(
                        PRIME,
                        addmod(/*column3_row197*/ mload(0x2260), /*column3_row197*/ mload(0x2260), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[58].
              res := addmod(res,
                            mulmod(val, /*coefficients[58]*/ mload(0xd80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column3_row251 - (column3_row252 + column3_row252)) * (column3_row197 - 18014398509481984 * column3_row251).
              let val := mulmod(
                addmod(
                  /*column3_row251*/ mload(0x2280),
                  sub(
                    PRIME,
                    addmod(/*column3_row252*/ mload(0x22a0), /*column3_row252*/ mload(0x22a0), PRIME)),
                  PRIME),
                addmod(
                  /*column3_row197*/ mload(0x2260),
                  sub(PRIME, mulmod(18014398509481984, /*column3_row251*/ mload(0x2280), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[59].
              res := addmod(res,
                            mulmod(val, /*coefficients[59]*/ mload(0xda0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[60].
              res := addmod(res,
                            mulmod(val, /*coefficients[60]*/ mload(0xdc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column3_row0.
              let val := /*column3_row0*/ mload(0x21c0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x5540), PRIME)

              // res += val * coefficients[61].
              res := addmod(res,
                            mulmod(val, /*coefficients[61]*/ mload(0xde0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column3_row0.
              let val := /*column3_row0*/ mload(0x21c0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x5520), PRIME)

              // res += val * coefficients[62].
              res := addmod(res,
                            mulmod(val, /*coefficients[62]*/ mload(0xe00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column2_row0 - pedersen__points__y) - column4_row0 * (column1_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300),
                  addmod(
                    /*column2_row0*/ mload(0x2140),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column4_row0*/ mload(0x22e0),
                    addmod(
                      /*column1_row0*/ mload(0x20a0),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[63].
              res := addmod(res,
                            mulmod(val, /*coefficients[63]*/ mload(0xe20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column4_row0 * column4_row0 - pedersen__hash0__ec_subset_sum__bit_0 * (column1_row0 + pedersen__points__x + column1_row1).
              let val := addmod(
                mulmod(/*column4_row0*/ mload(0x22e0), /*column4_row0*/ mload(0x22e0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300),
                    addmod(
                      addmod(
                        /*column1_row0*/ mload(0x20a0),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column1_row1*/ mload(0x20c0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[64].
              res := addmod(res,
                            mulmod(val, /*coefficients[64]*/ mload(0xe40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column2_row0 + column2_row1) - column4_row0 * (column1_row0 - column1_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x4300),
                  addmod(/*column2_row0*/ mload(0x2140), /*column2_row1*/ mload(0x2160), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column4_row0*/ mload(0x22e0),
                    addmod(/*column1_row0*/ mload(0x20a0), sub(PRIME, /*column1_row1*/ mload(0x20c0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[65].
              res := addmod(res,
                            mulmod(val, /*coefficients[65]*/ mload(0xe60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column1_row1 - column1_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x4320),
                addmod(/*column1_row1*/ mload(0x20c0), sub(PRIME, /*column1_row0*/ mload(0x20a0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[66].
              res := addmod(res,
                            mulmod(val, /*coefficients[66]*/ mload(0xe80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column2_row1 - column2_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x4320),
                addmod(/*column2_row1*/ mload(0x2160), sub(PRIME, /*column2_row0*/ mload(0x2140)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x4fa0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x53a0), PRIME)

              // res += val * coefficients[67].
              res := addmod(res,
                            mulmod(val, /*coefficients[67]*/ mload(0xea0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column1_row256 - column1_row255.
              let val := addmod(
                /*column1_row256*/ mload(0x2100),
                sub(PRIME, /*column1_row255*/ mload(0x20e0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5000), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[68].
              res := addmod(res,
                            mulmod(val, /*coefficients[68]*/ mload(0xec0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column2_row256 - column2_row255.
              let val := addmod(
                /*column2_row256*/ mload(0x21a0),
                sub(PRIME, /*column2_row255*/ mload(0x2180)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5000), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[69].
              res := addmod(res,
                            mulmod(val, /*coefficients[69]*/ mload(0xee0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column1_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column1_row0*/ mload(0x20a0),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x3a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[70].
              res := addmod(res,
                            mulmod(val, /*coefficients[70]*/ mload(0xf00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column2_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column2_row0*/ mload(0x2140),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x3c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[71].
              res := addmod(res,
                            mulmod(val, /*coefficients[71]*/ mload(0xf20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column5_row7 - column3_row0.
              let val := addmod(/*column5_row7*/ mload(0x2400), sub(PRIME, /*column3_row0*/ mload(0x21c0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[72].
              res := addmod(res,
                            mulmod(val, /*coefficients[72]*/ mload(0xf40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column5_row518 - (column5_row134 + 1).
              let val := addmod(
                /*column5_row518*/ mload(0x2760),
                sub(PRIME, addmod(/*column5_row134*/ mload(0x2580), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(512 * (trace_length / 512 - 1)).
              // val *= domains[36].
              val := mulmod(val, /*domains[36]*/ mload(0x5300), PRIME)
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[73].
              res := addmod(res,
                            mulmod(val, /*coefficients[73]*/ mload(0xf60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column5_row6 - initial_pedersen_addr.
              let val := addmod(
                /*column5_row6*/ mload(0x23e0),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x3e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[74].
              res := addmod(res,
                            mulmod(val, /*coefficients[74]*/ mload(0xf80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column5_row263 - column3_row256.
              let val := addmod(
                /*column5_row263*/ mload(0x2660),
                sub(PRIME, /*column3_row256*/ mload(0x22c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[75].
              res := addmod(res,
                            mulmod(val, /*coefficients[75]*/ mload(0xfa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column5_row262 - (column5_row6 + 1).
              let val := addmod(
                /*column5_row262*/ mload(0x2640),
                sub(PRIME, addmod(/*column5_row6*/ mload(0x23e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[76].
              res := addmod(res,
                            mulmod(val, /*coefficients[76]*/ mload(0xfc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column5_row135 - column1_row511.
              let val := addmod(
                /*column5_row135*/ mload(0x25a0),
                sub(PRIME, /*column1_row511*/ mload(0x2120)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[77].
              res := addmod(res,
                            mulmod(val, /*coefficients[77]*/ mload(0xfe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column5_row134 - (column5_row262 + 1).
              let val := addmod(
                /*column5_row134*/ mload(0x2580),
                sub(PRIME, addmod(/*column5_row262*/ mload(0x2640), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[78].
              res := addmod(res,
                            mulmod(val, /*coefficients[78]*/ mload(0x1000), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column5_row71.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x4420),
                sub(PRIME, /*column5_row71*/ mload(0x2520)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[79].
              res := addmod(res,
                            mulmod(val, /*coefficients[79]*/ mload(0x1020), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column5_row326 - (column5_row70 + 1).
              let val := addmod(
                /*column5_row326*/ mload(0x26a0),
                sub(PRIME, addmod(/*column5_row70*/ mload(0x2500), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= domains[37].
              val := mulmod(val, /*domains[37]*/ mload(0x5320), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[80].
              res := addmod(res,
                            mulmod(val, /*coefficients[80]*/ mload(0x1040), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column5_row70 - initial_rc_addr.
              let val := addmod(
                /*column5_row70*/ mload(0x2500),
                sub(PRIME, /*initial_rc_addr*/ mload(0x400)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[81].
              res := addmod(res,
                            mulmod(val, /*coefficients[81]*/ mload(0x1060), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/slope: ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa/sig_config.alpha - (column8_row33 + column8_row33) * column8_row35.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4440),
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4440),
                      PRIME),
                    /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4440),
                    PRIME),
                  /*ecdsa/sig_config.alpha*/ mload(0x420),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column8_row33*/ mload(0x3540), /*column8_row33*/ mload(0x3540), PRIME),
                    /*column8_row35*/ mload(0x3560),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[82].
              res := addmod(res,
                            mulmod(val, /*coefficients[82]*/ mload(0x1080), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/x: column8_row35 * column8_row35 - (column8_row1 + column8_row1 + column8_row65).
              let val := addmod(
                mulmod(/*column8_row35*/ mload(0x3560), /*column8_row35*/ mload(0x3560), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column8_row1*/ mload(0x3240), /*column8_row1*/ mload(0x3240), PRIME),
                    /*column8_row65*/ mload(0x3720),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[83].
              res := addmod(res,
                            mulmod(val, /*coefficients[83]*/ mload(0x10a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/y: column8_row33 + column8_row97 - column8_row35 * (column8_row1 - column8_row65).
              let val := addmod(
                addmod(/*column8_row33*/ mload(0x3540), /*column8_row97*/ mload(0x3840), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row35*/ mload(0x3560),
                    addmod(/*column8_row1*/ mload(0x3240), sub(PRIME, /*column8_row65*/ mload(0x3720)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[84].
              res := addmod(res,
                            mulmod(val, /*coefficients[84]*/ mload(0x10c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/booleanity_test: ecdsa__signature0__exponentiate_generator__bit_0 * (ecdsa__signature0__exponentiate_generator__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[85].
              res := addmod(res,
                            mulmod(val, /*coefficients[85]*/ mload(0x10e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/bit_extraction_end: column8_row59.
              let val := /*column8_row59*/ mload(0x36e0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5600), PRIME)

              // res += val * coefficients[86].
              res := addmod(res,
                            mulmod(val, /*coefficients[86]*/ mload(0x1100), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/zeros_tail: column8_row59.
              let val := /*column8_row59*/ mload(0x36e0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[87].
              res := addmod(res,
                            mulmod(val, /*coefficients[87]*/ mload(0x1120), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/slope: ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row91 - ecdsa__generator_points__y) - column8_row123 * (column8_row27 - ecdsa__generator_points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460),
                  addmod(
                    /*column8_row91*/ mload(0x3820),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/y*/ mload(0x60)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row123*/ mload(0x3900),
                    addmod(
                      /*column8_row27*/ mload(0x34e0),
                      sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[88].
              res := addmod(res,
                            mulmod(val, /*coefficients[88]*/ mload(0x1140), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x: column8_row123 * column8_row123 - ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row27 + ecdsa__generator_points__x + column8_row155).
              let val := addmod(
                mulmod(/*column8_row123*/ mload(0x3900), /*column8_row123*/ mload(0x3900), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460),
                    addmod(
                      addmod(
                        /*column8_row27*/ mload(0x34e0),
                        /*periodic_column/ecdsa/generator_points/x*/ mload(0x40),
                        PRIME),
                      /*column8_row155*/ mload(0x3920),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[89].
              res := addmod(res,
                            mulmod(val, /*coefficients[89]*/ mload(0x1160), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/y: ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row91 + column8_row219) - column8_row123 * (column8_row27 - column8_row155).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4460),
                  addmod(/*column8_row91*/ mload(0x3820), /*column8_row219*/ mload(0x39a0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row123*/ mload(0x3900),
                    addmod(
                      /*column8_row27*/ mload(0x34e0),
                      sub(PRIME, /*column8_row155*/ mload(0x3920)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[90].
              res := addmod(res,
                            mulmod(val, /*coefficients[90]*/ mload(0x1180), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv: column8_row7 * (column8_row27 - ecdsa__generator_points__x) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row7*/ mload(0x3300),
                  addmod(
                    /*column8_row27*/ mload(0x34e0),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[91].
              res := addmod(res,
                            mulmod(val, /*coefficients[91]*/ mload(0x11a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/x: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column8_row155 - column8_row27).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x4480),
                addmod(
                  /*column8_row155*/ mload(0x3920),
                  sub(PRIME, /*column8_row27*/ mload(0x34e0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[92].
              res := addmod(res,
                            mulmod(val, /*coefficients[92]*/ mload(0x11c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/y: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column8_row219 - column8_row91).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x4480),
                addmod(
                  /*column8_row219*/ mload(0x39a0),
                  sub(PRIME, /*column8_row91*/ mload(0x3820)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= domains[28].
              val := mulmod(val, /*domains[28]*/ mload(0x5200), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[93].
              res := addmod(res,
                            mulmod(val, /*coefficients[93]*/ mload(0x11e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/booleanity_test: ecdsa__signature0__exponentiate_key__bit_0 * (ecdsa__signature0__exponentiate_key__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[94].
              res := addmod(res,
                            mulmod(val, /*coefficients[94]*/ mload(0x1200), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/bit_extraction_end: column8_row9.
              let val := /*column8_row9*/ mload(0x3340)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[20].
              val := mulmod(val, /*denominator_invs[20]*/ mload(0x5620), PRIME)

              // res += val * coefficients[95].
              res := addmod(res,
                            mulmod(val, /*coefficients[95]*/ mload(0x1220), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/zeros_tail: column8_row9.
              let val := /*column8_row9*/ mload(0x3340)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, /*denominator_invs[16]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[96].
              res := addmod(res,
                            mulmod(val, /*coefficients[96]*/ mload(0x1240), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/slope: ecdsa__signature0__exponentiate_key__bit_0 * (column8_row49 - column8_row33) - column8_row19 * (column8_row17 - column8_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0),
                  addmod(/*column8_row49*/ mload(0x3640), sub(PRIME, /*column8_row33*/ mload(0x3540)), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row19*/ mload(0x3440),
                    addmod(/*column8_row17*/ mload(0x3420), sub(PRIME, /*column8_row1*/ mload(0x3240)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[97].
              res := addmod(res,
                            mulmod(val, /*coefficients[97]*/ mload(0x1260), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x: column8_row19 * column8_row19 - ecdsa__signature0__exponentiate_key__bit_0 * (column8_row17 + column8_row1 + column8_row81).
              let val := addmod(
                mulmod(/*column8_row19*/ mload(0x3440), /*column8_row19*/ mload(0x3440), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0),
                    addmod(
                      addmod(/*column8_row17*/ mload(0x3420), /*column8_row1*/ mload(0x3240), PRIME),
                      /*column8_row81*/ mload(0x37c0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[98].
              res := addmod(res,
                            mulmod(val, /*coefficients[98]*/ mload(0x1280), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/y: ecdsa__signature0__exponentiate_key__bit_0 * (column8_row49 + column8_row113) - column8_row19 * (column8_row17 - column8_row81).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x44a0),
                  addmod(/*column8_row49*/ mload(0x3640), /*column8_row113*/ mload(0x38c0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row19*/ mload(0x3440),
                    addmod(/*column8_row17*/ mload(0x3420), sub(PRIME, /*column8_row81*/ mload(0x37c0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[99].
              res := addmod(res,
                            mulmod(val, /*coefficients[99]*/ mload(0x12a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x_diff_inv: column8_row51 * (column8_row17 - column8_row1) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row51*/ mload(0x3660),
                  addmod(/*column8_row17*/ mload(0x3420), sub(PRIME, /*column8_row1*/ mload(0x3240)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[100].
              res := addmod(res,
                            mulmod(val, /*coefficients[100]*/ mload(0x12c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/x: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column8_row81 - column8_row17).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x44c0),
                addmod(/*column8_row81*/ mload(0x37c0), sub(PRIME, /*column8_row17*/ mload(0x3420)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[101].
              res := addmod(res,
                            mulmod(val, /*coefficients[101]*/ mload(0x12e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/y: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column8_row113 - column8_row49).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x44c0),
                addmod(
                  /*column8_row113*/ mload(0x38c0),
                  sub(PRIME, /*column8_row49*/ mload(0x3640)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[102].
              res := addmod(res,
                            mulmod(val, /*coefficients[102]*/ mload(0x1300), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/x: column8_row27 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column8_row27*/ mload(0x34e0),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x440)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[103].
              res := addmod(res,
                            mulmod(val, /*coefficients[103]*/ mload(0x1320), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/y: column8_row91 + ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column8_row91*/ mload(0x3820),
                /*ecdsa/sig_config.shift_point.y*/ mload(0x460),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[104].
              res := addmod(res,
                            mulmod(val, /*coefficients[104]*/ mload(0x1340), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/x: column8_row17 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column8_row17*/ mload(0x3420),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x440)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[105].
              res := addmod(res,
                            mulmod(val, /*coefficients[105]*/ mload(0x1360), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/y: column8_row49 - ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column8_row49*/ mload(0x3640),
                sub(PRIME, /*ecdsa/sig_config.shift_point.y*/ mload(0x460)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[106].
              res := addmod(res,
                            mulmod(val, /*coefficients[106]*/ mload(0x1380), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/slope: column8_row32731 - (column8_row16369 + column8_row32763 * (column8_row32667 - column8_row16337)).
              let val := addmod(
                /*column8_row32731*/ mload(0x3ec0),
                sub(
                  PRIME,
                  addmod(
                    /*column8_row16369*/ mload(0x3dc0),
                    mulmod(
                      /*column8_row32763*/ mload(0x3f20),
                      addmod(
                        /*column8_row32667*/ mload(0x3e60),
                        sub(PRIME, /*column8_row16337*/ mload(0x3d20)),
                        PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[107].
              res := addmod(res,
                            mulmod(val, /*coefficients[107]*/ mload(0x13a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x: column8_row32763 * column8_row32763 - (column8_row32667 + column8_row16337 + column8_row16385).
              let val := addmod(
                mulmod(/*column8_row32763*/ mload(0x3f20), /*column8_row32763*/ mload(0x3f20), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column8_row32667*/ mload(0x3e60), /*column8_row16337*/ mload(0x3d20), PRIME),
                    /*column8_row16385*/ mload(0x3e00),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[108].
              res := addmod(res,
                            mulmod(val, /*coefficients[108]*/ mload(0x13c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/y: column8_row32731 + column8_row16417 - column8_row32763 * (column8_row32667 - column8_row16385).
              let val := addmod(
                addmod(/*column8_row32731*/ mload(0x3ec0), /*column8_row16417*/ mload(0x3e20), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row32763*/ mload(0x3f20),
                    addmod(
                      /*column8_row32667*/ mload(0x3e60),
                      sub(PRIME, /*column8_row16385*/ mload(0x3e00)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[109].
              res := addmod(res,
                            mulmod(val, /*coefficients[109]*/ mload(0x13e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x_diff_inv: column8_row32647 * (column8_row32667 - column8_row16337) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row32647*/ mload(0x3e40),
                  addmod(
                    /*column8_row32667*/ mload(0x3e60),
                    sub(PRIME, /*column8_row16337*/ mload(0x3d20)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[110].
              res := addmod(res,
                            mulmod(val, /*coefficients[110]*/ mload(0x1400), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/slope: column8_row32753 + ecdsa/sig_config.shift_point.y - column8_row16331 * (column8_row32721 - ecdsa/sig_config.shift_point.x).
              let val := addmod(
                addmod(
                  /*column8_row32753*/ mload(0x3f00),
                  /*ecdsa/sig_config.shift_point.y*/ mload(0x460),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row16331*/ mload(0x3d00),
                    addmod(
                      /*column8_row32721*/ mload(0x3ea0),
                      sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x440)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[111].
              res := addmod(res,
                            mulmod(val, /*coefficients[111]*/ mload(0x1420), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x: column8_row16331 * column8_row16331 - (column8_row32721 + ecdsa/sig_config.shift_point.x + column8_row9).
              let val := addmod(
                mulmod(/*column8_row16331*/ mload(0x3d00), /*column8_row16331*/ mload(0x3d00), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*column8_row32721*/ mload(0x3ea0),
                      /*ecdsa/sig_config.shift_point.x*/ mload(0x440),
                      PRIME),
                    /*column8_row9*/ mload(0x3340),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[112].
              res := addmod(res,
                            mulmod(val, /*coefficients[112]*/ mload(0x1440), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x_diff_inv: column8_row32715 * (column8_row32721 - ecdsa/sig_config.shift_point.x) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row32715*/ mload(0x3e80),
                  addmod(
                    /*column8_row32721*/ mload(0x3ea0),
                    sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x440)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[113].
              res := addmod(res,
                            mulmod(val, /*coefficients[113]*/ mload(0x1460), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/z_nonzero: column8_row59 * column8_row16363 - 1.
              let val := addmod(
                mulmod(/*column8_row59*/ mload(0x36e0), /*column8_row16363*/ mload(0x3da0), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[114].
              res := addmod(res,
                            mulmod(val, /*coefficients[114]*/ mload(0x1480), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/r_and_w_nonzero: column8_row9 * column8_row16355 - 1.
              let val := addmod(
                mulmod(/*column8_row9*/ mload(0x3340), /*column8_row16355*/ mload(0x3d60), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[115].
              res := addmod(res,
                            mulmod(val, /*coefficients[115]*/ mload(0x14a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/x_squared: column8_row32747 - column8_row1 * column8_row1.
              let val := addmod(
                /*column8_row32747*/ mload(0x3ee0),
                sub(
                  PRIME,
                  mulmod(/*column8_row1*/ mload(0x3240), /*column8_row1*/ mload(0x3240), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[116].
              res := addmod(res,
                            mulmod(val, /*coefficients[116]*/ mload(0x14c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/on_curve: column8_row33 * column8_row33 - (column8_row1 * column8_row32747 + ecdsa/sig_config.alpha * column8_row1 + ecdsa/sig_config.beta).
              let val := addmod(
                mulmod(/*column8_row33*/ mload(0x3540), /*column8_row33*/ mload(0x3540), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(/*column8_row1*/ mload(0x3240), /*column8_row32747*/ mload(0x3ee0), PRIME),
                      mulmod(/*ecdsa/sig_config.alpha*/ mload(0x420), /*column8_row1*/ mload(0x3240), PRIME),
                      PRIME),
                    /*ecdsa/sig_config.beta*/ mload(0x480),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[117].
              res := addmod(res,
                            mulmod(val, /*coefficients[117]*/ mload(0x14e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/init_addr: column5_row390 - initial_ecdsa_addr.
              let val := addmod(
                /*column5_row390*/ mload(0x2700),
                sub(PRIME, /*initial_ecdsa_addr*/ mload(0x4a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[118].
              res := addmod(res,
                            mulmod(val, /*coefficients[118]*/ mload(0x1500), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_addr: column5_row16774 - (column5_row390 + 1).
              let val := addmod(
                /*column5_row16774*/ mload(0x2a20),
                sub(PRIME, addmod(/*column5_row390*/ mload(0x2700), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[119].
              res := addmod(res,
                            mulmod(val, /*coefficients[119]*/ mload(0x1520), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_addr: column5_row33158 - (column5_row16774 + 1).
              let val := addmod(
                /*column5_row33158*/ mload(0x2a80),
                sub(PRIME, addmod(/*column5_row16774*/ mload(0x2a20), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(32768 * (trace_length / 32768 - 1)).
              // val *= domains[38].
              val := mulmod(val, /*domains[38]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[120].
              res := addmod(res,
                            mulmod(val, /*coefficients[120]*/ mload(0x1540), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_value0: column5_row16775 - column8_row59.
              let val := addmod(
                /*column5_row16775*/ mload(0x2a40),
                sub(PRIME, /*column8_row59*/ mload(0x36e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[121].
              res := addmod(res,
                            mulmod(val, /*coefficients[121]*/ mload(0x1560), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_value0: column5_row391 - column8_row1.
              let val := addmod(/*column5_row391*/ mload(0x2720), sub(PRIME, /*column8_row1*/ mload(0x3240)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x5640), PRIME)

              // res += val * coefficients[122].
              res := addmod(res,
                            mulmod(val, /*coefficients[122]*/ mload(0x1580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/init_var_pool_addr: column5_row198 - initial_bitwise_addr.
              let val := addmod(
                /*column5_row198*/ mload(0x25e0),
                sub(PRIME, /*initial_bitwise_addr*/ mload(0x4c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[123].
              res := addmod(res,
                            mulmod(val, /*coefficients[123]*/ mload(0x15a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/step_var_pool_addr: column5_row454 - (column5_row198 + 1).
              let val := addmod(
                /*column5_row454*/ mload(0x2740),
                sub(PRIME, addmod(/*column5_row198*/ mload(0x25e0), 1, PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(3 * trace_length / 4).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5120), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[124].
              res := addmod(res,
                            mulmod(val, /*coefficients[124]*/ mload(0x15c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/x_or_y_addr: column5_row902 - (column5_row966 + 1).
              let val := addmod(
                /*column5_row902*/ mload(0x27c0),
                sub(PRIME, addmod(/*column5_row966*/ mload(0x2800), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[125].
              res := addmod(res,
                            mulmod(val, /*coefficients[125]*/ mload(0x15e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/next_var_pool_addr: column5_row1222 - (column5_row902 + 1).
              let val := addmod(
                /*column5_row1222*/ mload(0x2840),
                sub(PRIME, addmod(/*column5_row902*/ mload(0x27c0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(1024 * (trace_length / 1024 - 1)).
              // val *= domains[39].
              val := mulmod(val, /*domains[39]*/ mload(0x5360), PRIME)
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[126].
              res := addmod(res,
                            mulmod(val, /*coefficients[126]*/ mload(0x1600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/partition: bitwise__sum_var_0_0 + bitwise__sum_var_8_0 - column5_row199.
              let val := addmod(
                addmod(
                  /*intermediate_value/bitwise/sum_var_0_0*/ mload(0x44e0),
                  /*intermediate_value/bitwise/sum_var_8_0*/ mload(0x4500),
                  PRIME),
                sub(PRIME, /*column5_row199*/ mload(0x2600)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5500), PRIME)

              // res += val * coefficients[127].
              res := addmod(res,
                            mulmod(val, /*coefficients[127]*/ mload(0x1620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/or_is_and_plus_xor: column5_row903 - (column5_row711 + column5_row967).
              let val := addmod(
                /*column5_row903*/ mload(0x27e0),
                sub(
                  PRIME,
                  addmod(/*column5_row711*/ mload(0x27a0), /*column5_row967*/ mload(0x2820), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[128].
              res := addmod(res,
                            mulmod(val, /*coefficients[128]*/ mload(0x1640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/addition_is_xor_with_and: column7_row1 + column7_row257 - (column7_row769 + column7_row513 + column7_row513).
              let val := addmod(
                addmod(/*column7_row1*/ mload(0x2b40), /*column7_row257*/ mload(0x3000), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column7_row769*/ mload(0x3160), /*column7_row513*/ mload(0x30a0), PRIME),
                    /*column7_row513*/ mload(0x30a0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: (point^(trace_length / 1024) - trace_generator^(trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 16)) * (point^(trace_length / 1024) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(trace_length / 8)) * (point^(trace_length / 1024) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 1024) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 1024) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 1024) - trace_generator^(15 * trace_length / 64)) * domain22.
              // val *= denominator_invs[24].
              val := mulmod(val, /*denominator_invs[24]*/ mload(0x56a0), PRIME)

              // res += val * coefficients[129].
              res := addmod(res,
                            mulmod(val, /*coefficients[129]*/ mload(0x1660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking192: (column7_row705 + column7_row961) * 16 - column7_row9.
              let val := addmod(
                mulmod(
                  addmod(/*column7_row705*/ mload(0x30e0), /*column7_row961*/ mload(0x31a0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column7_row9*/ mload(0x2c40)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[130].
              res := addmod(res,
                            mulmod(val, /*coefficients[130]*/ mload(0x1680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking193: (column7_row721 + column7_row977) * 16 - column7_row521.
              let val := addmod(
                mulmod(
                  addmod(/*column7_row721*/ mload(0x3100), /*column7_row977*/ mload(0x31c0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column7_row521*/ mload(0x30c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[131].
              res := addmod(res,
                            mulmod(val, /*coefficients[131]*/ mload(0x16a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking194: (column7_row737 + column7_row993) * 16 - column7_row265.
              let val := addmod(
                mulmod(
                  addmod(/*column7_row737*/ mload(0x3120), /*column7_row993*/ mload(0x31e0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column7_row265*/ mload(0x3020)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[132].
              res := addmod(res,
                            mulmod(val, /*coefficients[132]*/ mload(0x16c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking195: (column7_row753 + column7_row1009) * 256 - column7_row777.
              let val := addmod(
                mulmod(
                  addmod(/*column7_row753*/ mload(0x3140), /*column7_row1009*/ mload(0x3200), PRIME),
                  256,
                  PRIME),
                sub(PRIME, /*column7_row777*/ mload(0x3180)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[23].
              val := mulmod(val, /*denominator_invs[23]*/ mload(0x5680), PRIME)

              // res += val * coefficients[133].
              res := addmod(res,
                            mulmod(val, /*coefficients[133]*/ mload(0x16e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/init_addr: column5_row8582 - initial_ec_op_addr.
              let val := addmod(
                /*column5_row8582*/ mload(0x2920),
                sub(PRIME, /*initial_ec_op_addr*/ mload(0x4e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[134].
              res := addmod(res,
                            mulmod(val, /*coefficients[134]*/ mload(0x1700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/p_x_addr: column5_row24966 - (column5_row8582 + 7).
              let val := addmod(
                /*column5_row24966*/ mload(0x2a60),
                sub(PRIME, addmod(/*column5_row8582*/ mload(0x2920), 7, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16384 * (trace_length / 16384 - 1)).
              // val *= domains[40].
              val := mulmod(val, /*domains[40]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[135].
              res := addmod(res,
                            mulmod(val, /*coefficients[135]*/ mload(0x1720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/p_y_addr: column5_row4486 - (column5_row8582 + 1).
              let val := addmod(
                /*column5_row4486*/ mload(0x28a0),
                sub(PRIME, addmod(/*column5_row8582*/ mload(0x2920), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[136].
              res := addmod(res,
                            mulmod(val, /*coefficients[136]*/ mload(0x1740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/q_x_addr: column5_row12678 - (column5_row4486 + 1).
              let val := addmod(
                /*column5_row12678*/ mload(0x29a0),
                sub(PRIME, addmod(/*column5_row4486*/ mload(0x28a0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[137].
              res := addmod(res,
                            mulmod(val, /*coefficients[137]*/ mload(0x1760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/q_y_addr: column5_row2438 - (column5_row12678 + 1).
              let val := addmod(
                /*column5_row2438*/ mload(0x2860),
                sub(PRIME, addmod(/*column5_row12678*/ mload(0x29a0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[138].
              res := addmod(res,
                            mulmod(val, /*coefficients[138]*/ mload(0x1780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/m_addr: column5_row10630 - (column5_row2438 + 1).
              let val := addmod(
                /*column5_row10630*/ mload(0x2960),
                sub(PRIME, addmod(/*column5_row2438*/ mload(0x2860), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[139].
              res := addmod(res,
                            mulmod(val, /*coefficients[139]*/ mload(0x17a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/r_x_addr: column5_row6534 - (column5_row10630 + 1).
              let val := addmod(
                /*column5_row6534*/ mload(0x28e0),
                sub(PRIME, addmod(/*column5_row10630*/ mload(0x2960), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[140].
              res := addmod(res,
                            mulmod(val, /*coefficients[140]*/ mload(0x17c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/r_y_addr: column5_row14726 - (column5_row6534 + 1).
              let val := addmod(
                /*column5_row14726*/ mload(0x29e0),
                sub(PRIME, addmod(/*column5_row6534*/ mload(0x28e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[141].
              res := addmod(res,
                            mulmod(val, /*coefficients[141]*/ mload(0x17e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/slope: ec_op__doubling_q__x_squared_0 + ec_op__doubling_q__x_squared_0 + ec_op__doubling_q__x_squared_0 + ec_op/curve_config.alpha - (column8_row25 + column8_row25) * column8_row57.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4520),
                      /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4520),
                      PRIME),
                    /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4520),
                    PRIME),
                  /*ec_op/curve_config.alpha*/ mload(0x500),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column8_row25*/ mload(0x34c0), /*column8_row25*/ mload(0x34c0), PRIME),
                    /*column8_row57*/ mload(0x36c0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[142].
              res := addmod(res,
                            mulmod(val, /*coefficients[142]*/ mload(0x1800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/x: column8_row57 * column8_row57 - (column8_row41 + column8_row41 + column8_row105).
              let val := addmod(
                mulmod(/*column8_row57*/ mload(0x36c0), /*column8_row57*/ mload(0x36c0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column8_row41*/ mload(0x35c0), /*column8_row41*/ mload(0x35c0), PRIME),
                    /*column8_row105*/ mload(0x3880),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[143].
              res := addmod(res,
                            mulmod(val, /*coefficients[143]*/ mload(0x1820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/y: column8_row25 + column8_row89 - column8_row57 * (column8_row41 - column8_row105).
              let val := addmod(
                addmod(/*column8_row25*/ mload(0x34c0), /*column8_row89*/ mload(0x3800), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row57*/ mload(0x36c0),
                    addmod(
                      /*column8_row41*/ mload(0x35c0),
                      sub(PRIME, /*column8_row105*/ mload(0x3880)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[144].
              res := addmod(res,
                            mulmod(val, /*coefficients[144]*/ mload(0x1840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_q_x: column5_row12679 - column8_row41.
              let val := addmod(
                /*column5_row12679*/ mload(0x29c0),
                sub(PRIME, /*column8_row41*/ mload(0x35c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[145].
              res := addmod(res,
                            mulmod(val, /*coefficients[145]*/ mload(0x1860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_q_y: column5_row2439 - column8_row25.
              let val := addmod(
                /*column5_row2439*/ mload(0x2880),
                sub(PRIME, /*column8_row25*/ mload(0x34c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[146].
              res := addmod(res,
                            mulmod(val, /*coefficients[146]*/ mload(0x1880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/last_one_is_zero: column8_row16371 * (column8_row21 - (column8_row85 + column8_row85)).
              let val := mulmod(
                /*column8_row16371*/ mload(0x3de0),
                addmod(
                  /*column8_row21*/ mload(0x3460),
                  sub(
                    PRIME,
                    addmod(/*column8_row85*/ mload(0x37e0), /*column8_row85*/ mload(0x37e0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[147].
              res := addmod(res,
                            mulmod(val, /*coefficients[147]*/ mload(0x18a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column8_row16371 * (column8_row85 - 3138550867693340381917894711603833208051177722232017256448 * column8_row12309).
              let val := mulmod(
                /*column8_row16371*/ mload(0x3de0),
                addmod(
                  /*column8_row85*/ mload(0x37e0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column8_row12309*/ mload(0x3c20),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[148].
              res := addmod(res,
                            mulmod(val, /*coefficients[148]*/ mload(0x18c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/cumulative_bit192: column8_row16371 - column8_row16339 * (column8_row12309 - (column8_row12373 + column8_row12373)).
              let val := addmod(
                /*column8_row16371*/ mload(0x3de0),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row16339*/ mload(0x3d40),
                    addmod(
                      /*column8_row12309*/ mload(0x3c20),
                      sub(
                        PRIME,
                        addmod(/*column8_row12373*/ mload(0x3c40), /*column8_row12373*/ mload(0x3c40), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[149].
              res := addmod(res,
                            mulmod(val, /*coefficients[149]*/ mload(0x18e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column8_row16339 * (column8_row12373 - 8 * column8_row12565).
              let val := mulmod(
                /*column8_row16339*/ mload(0x3d40),
                addmod(
                  /*column8_row12373*/ mload(0x3c40),
                  sub(PRIME, mulmod(8, /*column8_row12565*/ mload(0x3c60), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[150].
              res := addmod(res,
                            mulmod(val, /*coefficients[150]*/ mload(0x1900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/cumulative_bit196: column8_row16339 - (column8_row16085 - (column8_row16149 + column8_row16149)) * (column8_row12565 - (column8_row12629 + column8_row12629)).
              let val := addmod(
                /*column8_row16339*/ mload(0x3d40),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column8_row16085*/ mload(0x3ca0),
                      sub(
                        PRIME,
                        addmod(/*column8_row16149*/ mload(0x3cc0), /*column8_row16149*/ mload(0x3cc0), PRIME)),
                      PRIME),
                    addmod(
                      /*column8_row12565*/ mload(0x3c60),
                      sub(
                        PRIME,
                        addmod(/*column8_row12629*/ mload(0x3c80), /*column8_row12629*/ mload(0x3c80), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[151].
              res := addmod(res,
                            mulmod(val, /*coefficients[151]*/ mload(0x1920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column8_row16085 - (column8_row16149 + column8_row16149)) * (column8_row12629 - 18014398509481984 * column8_row16085).
              let val := mulmod(
                addmod(
                  /*column8_row16085*/ mload(0x3ca0),
                  sub(
                    PRIME,
                    addmod(/*column8_row16149*/ mload(0x3cc0), /*column8_row16149*/ mload(0x3cc0), PRIME)),
                  PRIME),
                addmod(
                  /*column8_row12629*/ mload(0x3c80),
                  sub(PRIME, mulmod(18014398509481984, /*column8_row16085*/ mload(0x3ca0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[152].
              res := addmod(res,
                            mulmod(val, /*coefficients[152]*/ mload(0x1940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/booleanity_test: ec_op__ec_subset_sum__bit_0 * (ec_op__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540),
                addmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[153].
              res := addmod(res,
                            mulmod(val, /*coefficients[153]*/ mload(0x1960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_extraction_end: column8_row21.
              let val := /*column8_row21*/ mload(0x3460)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[25].
              val := mulmod(val, /*denominator_invs[25]*/ mload(0x56c0), PRIME)

              // res += val * coefficients[154].
              res := addmod(res,
                            mulmod(val, /*coefficients[154]*/ mload(0x1980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/zeros_tail: column8_row21.
              let val := /*column8_row21*/ mload(0x3460)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, /*denominator_invs[16]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[155].
              res := addmod(res,
                            mulmod(val, /*coefficients[155]*/ mload(0x19a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/slope: ec_op__ec_subset_sum__bit_0 * (column8_row37 - column8_row25) - column8_row11 * (column8_row5 - column8_row41).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540),
                  addmod(/*column8_row37*/ mload(0x3580), sub(PRIME, /*column8_row25*/ mload(0x34c0)), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row11*/ mload(0x3380),
                    addmod(/*column8_row5*/ mload(0x32c0), sub(PRIME, /*column8_row41*/ mload(0x35c0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[156].
              res := addmod(res,
                            mulmod(val, /*coefficients[156]*/ mload(0x19c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/x: column8_row11 * column8_row11 - ec_op__ec_subset_sum__bit_0 * (column8_row5 + column8_row41 + column8_row69).
              let val := addmod(
                mulmod(/*column8_row11*/ mload(0x3380), /*column8_row11*/ mload(0x3380), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540),
                    addmod(
                      addmod(/*column8_row5*/ mload(0x32c0), /*column8_row41*/ mload(0x35c0), PRIME),
                      /*column8_row69*/ mload(0x3740),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[157].
              res := addmod(res,
                            mulmod(val, /*coefficients[157]*/ mload(0x19e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/y: ec_op__ec_subset_sum__bit_0 * (column8_row37 + column8_row101) - column8_row11 * (column8_row5 - column8_row69).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4540),
                  addmod(/*column8_row37*/ mload(0x3580), /*column8_row101*/ mload(0x3860), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row11*/ mload(0x3380),
                    addmod(/*column8_row5*/ mload(0x32c0), sub(PRIME, /*column8_row69*/ mload(0x3740)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[158].
              res := addmod(res,
                            mulmod(val, /*coefficients[158]*/ mload(0x1a00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/x_diff_inv: column8_row43 * (column8_row5 - column8_row41) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row43*/ mload(0x35e0),
                  addmod(/*column8_row5*/ mload(0x32c0), sub(PRIME, /*column8_row41*/ mload(0x35c0)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[159].
              res := addmod(res,
                            mulmod(val, /*coefficients[159]*/ mload(0x1a20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/copy_point/x: ec_op__ec_subset_sum__bit_neg_0 * (column8_row69 - column8_row5).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_neg_0*/ mload(0x4560),
                addmod(/*column8_row69*/ mload(0x3740), sub(PRIME, /*column8_row5*/ mload(0x32c0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[160].
              res := addmod(res,
                            mulmod(val, /*coefficients[160]*/ mload(0x1a40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/copy_point/y: ec_op__ec_subset_sum__bit_neg_0 * (column8_row101 - column8_row37).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_neg_0*/ mload(0x4560),
                addmod(
                  /*column8_row101*/ mload(0x3860),
                  sub(PRIME, /*column8_row37*/ mload(0x3580)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x5180), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[161].
              res := addmod(res,
                            mulmod(val, /*coefficients[161]*/ mload(0x1a60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_m: column8_row21 - column5_row10631.
              let val := addmod(
                /*column8_row21*/ mload(0x3460),
                sub(PRIME, /*column5_row10631*/ mload(0x2980)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[162].
              res := addmod(res,
                            mulmod(val, /*coefficients[162]*/ mload(0x1a80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_p_x: column5_row8583 - column8_row5.
              let val := addmod(
                /*column5_row8583*/ mload(0x2940),
                sub(PRIME, /*column8_row5*/ mload(0x32c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[163].
              res := addmod(res,
                            mulmod(val, /*coefficients[163]*/ mload(0x1aa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_p_y: column5_row4487 - column8_row37.
              let val := addmod(
                /*column5_row4487*/ mload(0x28c0),
                sub(PRIME, /*column8_row37*/ mload(0x3580)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[164].
              res := addmod(res,
                            mulmod(val, /*coefficients[164]*/ mload(0x1ac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/set_r_x: column5_row6535 - column8_row16325.
              let val := addmod(
                /*column5_row6535*/ mload(0x2900),
                sub(PRIME, /*column8_row16325*/ mload(0x3ce0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[165].
              res := addmod(res,
                            mulmod(val, /*coefficients[165]*/ mload(0x1ae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/set_r_y: column5_row14727 - column8_row16357.
              let val := addmod(
                /*column5_row14727*/ mload(0x2a00),
                sub(PRIME, /*column8_row16357*/ mload(0x3d80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x5660), PRIME)

              // res += val * coefficients[166].
              res := addmod(res,
                            mulmod(val, /*coefficients[166]*/ mload(0x1b00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/init_input_output_addr: column5_row38 - initial_poseidon_addr.
              let val := addmod(
                /*column5_row38*/ mload(0x24c0),
                sub(PRIME, /*initial_poseidon_addr*/ mload(0x520)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x5420), PRIME)

              // res += val * coefficients[167].
              res := addmod(res,
                            mulmod(val, /*coefficients[167]*/ mload(0x1b20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/addr_input_output_step_inner: column5_row102 - (column5_row38 + 1).
              let val := addmod(
                /*column5_row102*/ mload(0x2540),
                sub(PRIME, addmod(/*column5_row38*/ mload(0x24c0), 1, PRIME)),
                PRIME)

              // Numerator: (point^(trace_length / 512) - trace_generator^(5 * trace_length / 8)) * domain14.
              // val *= domains[15].
              val := mulmod(val, /*domains[15]*/ mload(0x5060), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[168].
              res := addmod(res,
                            mulmod(val, /*coefficients[168]*/ mload(0x1b40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/addr_input_output_step_outter: column5_row550 - (column5_row358 + 1).
              let val := addmod(
                /*column5_row550*/ mload(0x2780),
                sub(PRIME, addmod(/*column5_row358*/ mload(0x26c0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(512 * (trace_length / 512 - 1)).
              // val *= domains[36].
              val := mulmod(val, /*domains[36]*/ mload(0x5300), PRIME)
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[169].
              res := addmod(res,
                            mulmod(val, /*coefficients[169]*/ mload(0x1b60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_rounds_state0_squaring: column8_row53 * column8_row53 - column8_row29.
              let val := addmod(
                mulmod(/*column8_row53*/ mload(0x3680), /*column8_row53*/ mload(0x3680), PRIME),
                sub(PRIME, /*column8_row29*/ mload(0x3500)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[170].
              res := addmod(res,
                            mulmod(val, /*coefficients[170]*/ mload(0x1b80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_rounds_state1_squaring: column8_row13 * column8_row13 - column8_row61.
              let val := addmod(
                mulmod(/*column8_row13*/ mload(0x33c0), /*column8_row13*/ mload(0x33c0), PRIME),
                sub(PRIME, /*column8_row61*/ mload(0x3700)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[171].
              res := addmod(res,
                            mulmod(val, /*coefficients[171]*/ mload(0x1ba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_rounds_state2_squaring: column8_row45 * column8_row45 - column8_row3.
              let val := addmod(
                mulmod(/*column8_row45*/ mload(0x3600), /*column8_row45*/ mload(0x3600), PRIME),
                sub(PRIME, /*column8_row3*/ mload(0x3280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[172].
              res := addmod(res,
                            mulmod(val, /*coefficients[172]*/ mload(0x1bc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/partial_rounds_state0_squaring: column7_row3 * column7_row3 - column7_row7.
              let val := addmod(
                mulmod(/*column7_row3*/ mload(0x2b80), /*column7_row3*/ mload(0x2b80), PRIME),
                sub(PRIME, /*column7_row7*/ mload(0x2c00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[173].
              res := addmod(res,
                            mulmod(val, /*coefficients[173]*/ mload(0x1be0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/partial_rounds_state1_squaring: column8_row6 * column8_row6 - column8_row14.
              let val := addmod(
                mulmod(/*column8_row6*/ mload(0x32e0), /*column8_row6*/ mload(0x32e0), PRIME),
                sub(PRIME, /*column8_row14*/ mload(0x33e0)),
                PRIME)

              // Numerator: domain14 * domain17.
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x50c0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[174].
              res := addmod(res,
                            mulmod(val, /*coefficients[174]*/ mload(0x1c00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/add_first_round_key0: column5_row39 + 2950795762459345168613727575620414179244544320470208355568817838579231751791 - column8_row53.
              let val := addmod(
                addmod(
                  /*column5_row39*/ mload(0x24e0),
                  2950795762459345168613727575620414179244544320470208355568817838579231751791,
                  PRIME),
                sub(PRIME, /*column8_row53*/ mload(0x3680)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[175].
              res := addmod(res,
                            mulmod(val, /*coefficients[175]*/ mload(0x1c20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/add_first_round_key1: column5_row103 + 1587446564224215276866294500450702039420286416111469274423465069420553242820 - column8_row13.
              let val := addmod(
                addmod(
                  /*column5_row103*/ mload(0x2560),
                  1587446564224215276866294500450702039420286416111469274423465069420553242820,
                  PRIME),
                sub(PRIME, /*column8_row13*/ mload(0x33c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[176].
              res := addmod(res,
                            mulmod(val, /*coefficients[176]*/ mload(0x1c40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/add_first_round_key2: column5_row167 + 1645965921169490687904413452218868659025437693527479459426157555728339600137 - column8_row45.
              let val := addmod(
                addmod(
                  /*column5_row167*/ mload(0x25c0),
                  1645965921169490687904413452218868659025437693527479459426157555728339600137,
                  PRIME),
                sub(PRIME, /*column8_row45*/ mload(0x3600)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[177].
              res := addmod(res,
                            mulmod(val, /*coefficients[177]*/ mload(0x1c60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_round0: column8_row117 - (poseidon__poseidon__full_rounds_state0_cubed_0 + poseidon__poseidon__full_rounds_state0_cubed_0 + poseidon__poseidon__full_rounds_state0_cubed_0 + poseidon__poseidon__full_rounds_state1_cubed_0 + poseidon__poseidon__full_rounds_state2_cubed_0 + poseidon__poseidon__full_round_key0).
              let val := addmod(
                /*column8_row117*/ mload(0x38e0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0*/ mload(0x4580),
                            /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0*/ mload(0x4580),
                            PRIME),
                          /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0*/ mload(0x4580),
                          PRIME),
                        /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_0*/ mload(0x45a0),
                        PRIME),
                      /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_0*/ mload(0x45c0),
                      PRIME),
                    /*periodic_column/poseidon/poseidon/full_round_key0*/ mload(0x80),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(3 * trace_length / 4).
              // val *= domains[11].
              val := mulmod(val, /*domains[11]*/ mload(0x4fe0), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[178].
              res := addmod(res,
                            mulmod(val, /*coefficients[178]*/ mload(0x1c80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_round1: column8_row77 + poseidon__poseidon__full_rounds_state1_cubed_0 - (poseidon__poseidon__full_rounds_state0_cubed_0 + poseidon__poseidon__full_rounds_state2_cubed_0 + poseidon__poseidon__full_round_key1).
              let val := addmod(
                addmod(
                  /*column8_row77*/ mload(0x37a0),
                  /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_0*/ mload(0x45a0),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0*/ mload(0x4580),
                      /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_0*/ mload(0x45c0),
                      PRIME),
                    /*periodic_column/poseidon/poseidon/full_round_key1*/ mload(0xa0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(3 * trace_length / 4).
              // val *= domains[11].
              val := mulmod(val, /*domains[11]*/ mload(0x4fe0), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[179].
              res := addmod(res,
                            mulmod(val, /*coefficients[179]*/ mload(0x1ca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/full_round2: column8_row109 + poseidon__poseidon__full_rounds_state2_cubed_0 + poseidon__poseidon__full_rounds_state2_cubed_0 - (poseidon__poseidon__full_rounds_state0_cubed_0 + poseidon__poseidon__full_rounds_state1_cubed_0 + poseidon__poseidon__full_round_key2).
              let val := addmod(
                addmod(
                  addmod(
                    /*column8_row109*/ mload(0x38a0),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_0*/ mload(0x45c0),
                    PRIME),
                  /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_0*/ mload(0x45c0),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_0*/ mload(0x4580),
                      /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_0*/ mload(0x45a0),
                      PRIME),
                    /*periodic_column/poseidon/poseidon/full_round_key2*/ mload(0xc0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(3 * trace_length / 4).
              // val *= domains[11].
              val := mulmod(val, /*domains[11]*/ mload(0x4fe0), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5580), PRIME)

              // res += val * coefficients[180].
              res := addmod(res,
                            mulmod(val, /*coefficients[180]*/ mload(0x1cc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/last_full_round0: column5_row231 - (poseidon__poseidon__full_rounds_state0_cubed_7 + poseidon__poseidon__full_rounds_state0_cubed_7 + poseidon__poseidon__full_rounds_state0_cubed_7 + poseidon__poseidon__full_rounds_state1_cubed_7 + poseidon__poseidon__full_rounds_state2_cubed_7).
              let val := addmod(
                /*column5_row231*/ mload(0x2620),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7*/ mload(0x45e0),
                          /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7*/ mload(0x45e0),
                          PRIME),
                        /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7*/ mload(0x45e0),
                        PRIME),
                      /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_7*/ mload(0x4600),
                      PRIME),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_7*/ mload(0x4620),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[181].
              res := addmod(res,
                            mulmod(val, /*coefficients[181]*/ mload(0x1ce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/last_full_round1: column5_row295 + poseidon__poseidon__full_rounds_state1_cubed_7 - (poseidon__poseidon__full_rounds_state0_cubed_7 + poseidon__poseidon__full_rounds_state2_cubed_7).
              let val := addmod(
                addmod(
                  /*column5_row295*/ mload(0x2680),
                  /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_7*/ mload(0x4600),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7*/ mload(0x45e0),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_7*/ mload(0x4620),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[182].
              res := addmod(res,
                            mulmod(val, /*coefficients[182]*/ mload(0x1d00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/last_full_round2: column5_row359 + poseidon__poseidon__full_rounds_state2_cubed_7 + poseidon__poseidon__full_rounds_state2_cubed_7 - (poseidon__poseidon__full_rounds_state0_cubed_7 + poseidon__poseidon__full_rounds_state1_cubed_7).
              let val := addmod(
                addmod(
                  addmod(
                    /*column5_row359*/ mload(0x26e0),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_7*/ mload(0x4620),
                    PRIME),
                  /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_7*/ mload(0x4620),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_7*/ mload(0x45e0),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_7*/ mload(0x4600),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[183].
              res := addmod(res,
                            mulmod(val, /*coefficients[183]*/ mload(0x1d20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/copy_partial_rounds0_i0: column7_row491 - column8_row6.
              let val := addmod(/*column7_row491*/ mload(0x3040), sub(PRIME, /*column8_row6*/ mload(0x32e0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[184].
              res := addmod(res,
                            mulmod(val, /*coefficients[184]*/ mload(0x1d40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/copy_partial_rounds0_i1: column7_row499 - column8_row22.
              let val := addmod(
                /*column7_row499*/ mload(0x3060),
                sub(PRIME, /*column8_row22*/ mload(0x3480)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[185].
              res := addmod(res,
                            mulmod(val, /*coefficients[185]*/ mload(0x1d60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/copy_partial_rounds0_i2: column7_row507 - column8_row38.
              let val := addmod(
                /*column7_row507*/ mload(0x3080),
                sub(PRIME, /*column8_row38*/ mload(0x35a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[186].
              res := addmod(res,
                            mulmod(val, /*coefficients[186]*/ mload(0x1d80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_full_to_partial0: column7_row3 + poseidon__poseidon__full_rounds_state2_cubed_3 + poseidon__poseidon__full_rounds_state2_cubed_3 - (poseidon__poseidon__full_rounds_state0_cubed_3 + poseidon__poseidon__full_rounds_state1_cubed_3 + 2121140748740143694053732746913428481442990369183417228688865837805149503386).
              let val := addmod(
                addmod(
                  addmod(
                    /*column7_row3*/ mload(0x2b80),
                    /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_3*/ mload(0x4680),
                    PRIME),
                  /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_3*/ mload(0x4680),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/poseidon/poseidon/full_rounds_state0_cubed_3*/ mload(0x4640),
                      /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_3*/ mload(0x4660),
                      PRIME),
                    2121140748740143694053732746913428481442990369183417228688865837805149503386,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[187].
              res := addmod(res,
                            mulmod(val, /*coefficients[187]*/ mload(0x1da0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_full_to_partial1: column7_row11 - (3618502788666131213697322783095070105623107215331596699973092056135872020477 * poseidon__poseidon__full_rounds_state1_cubed_3 + 10 * poseidon__poseidon__full_rounds_state2_cubed_3 + 4 * column7_row3 + 3618502788666131213697322783095070105623107215331596699973092056135872020479 * poseidon__poseidon__partial_rounds_state0_cubed_0 + 2006642341318481906727563724340978325665491359415674592697055778067937914672).
              let val := addmod(
                /*column7_row11*/ mload(0x2c60),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            3618502788666131213697322783095070105623107215331596699973092056135872020477,
                            /*intermediate_value/poseidon/poseidon/full_rounds_state1_cubed_3*/ mload(0x4660),
                            PRIME),
                          mulmod(
                            10,
                            /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_3*/ mload(0x4680),
                            PRIME),
                          PRIME),
                        mulmod(4, /*column7_row3*/ mload(0x2b80), PRIME),
                        PRIME),
                      mulmod(
                        3618502788666131213697322783095070105623107215331596699973092056135872020479,
                        /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_0*/ mload(0x46a0),
                        PRIME),
                      PRIME),
                    2006642341318481906727563724340978325665491359415674592697055778067937914672,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[188].
              res := addmod(res,
                            mulmod(val, /*coefficients[188]*/ mload(0x1dc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_full_to_partial2: column7_row19 - (8 * poseidon__poseidon__full_rounds_state2_cubed_3 + 4 * column7_row3 + 6 * poseidon__poseidon__partial_rounds_state0_cubed_0 + column7_row11 + column7_row11 + 3618502788666131213697322783095070105623107215331596699973092056135872020479 * poseidon__poseidon__partial_rounds_state0_cubed_1 + 427751140904099001132521606468025610873158555767197326325930641757709538586).
              let val := addmod(
                /*column7_row19*/ mload(0x2d00),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            addmod(
                              mulmod(
                                8,
                                /*intermediate_value/poseidon/poseidon/full_rounds_state2_cubed_3*/ mload(0x4680),
                                PRIME),
                              mulmod(4, /*column7_row3*/ mload(0x2b80), PRIME),
                              PRIME),
                            mulmod(
                              6,
                              /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_0*/ mload(0x46a0),
                              PRIME),
                            PRIME),
                          /*column7_row11*/ mload(0x2c60),
                          PRIME),
                        /*column7_row11*/ mload(0x2c60),
                        PRIME),
                      mulmod(
                        3618502788666131213697322783095070105623107215331596699973092056135872020479,
                        /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_1*/ mload(0x46c0),
                        PRIME),
                      PRIME),
                    427751140904099001132521606468025610873158555767197326325930641757709538586,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[189].
              res := addmod(res,
                            mulmod(val, /*coefficients[189]*/ mload(0x1de0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/partial_round0: column7_row27 - (8 * poseidon__poseidon__partial_rounds_state0_cubed_0 + 4 * column7_row11 + 6 * poseidon__poseidon__partial_rounds_state0_cubed_1 + column7_row19 + column7_row19 + 3618502788666131213697322783095070105623107215331596699973092056135872020479 * poseidon__poseidon__partial_rounds_state0_cubed_2 + poseidon__poseidon__partial_round_key0).
              let val := addmod(
                /*column7_row27*/ mload(0x2d40),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            addmod(
                              mulmod(
                                8,
                                /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_0*/ mload(0x46a0),
                                PRIME),
                              mulmod(4, /*column7_row11*/ mload(0x2c60), PRIME),
                              PRIME),
                            mulmod(
                              6,
                              /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_1*/ mload(0x46c0),
                              PRIME),
                            PRIME),
                          /*column7_row19*/ mload(0x2d00),
                          PRIME),
                        /*column7_row19*/ mload(0x2d00),
                        PRIME),
                      mulmod(
                        3618502788666131213697322783095070105623107215331596699973092056135872020479,
                        /*intermediate_value/poseidon/poseidon/partial_rounds_state0_cubed_2*/ mload(0x46e0),
                        PRIME),
                      PRIME),
                    /*periodic_column/poseidon/poseidon/partial_round_key0*/ mload(0xe0),
                    PRIME)),
                PRIME)

              // Numerator: (point^(trace_length / 512) - trace_generator^(61 * trace_length / 64)) * (point^(trace_length / 512) - trace_generator^(63 * trace_length / 64)) * domain16.
              // val *= domains[19].
              val := mulmod(val, /*domains[19]*/ mload(0x50e0), PRIME)
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5480), PRIME)

              // res += val * coefficients[190].
              res := addmod(res,
                            mulmod(val, /*coefficients[190]*/ mload(0x1e00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/partial_round1: column8_row54 - (8 * poseidon__poseidon__partial_rounds_state1_cubed_0 + 4 * column8_row22 + 6 * poseidon__poseidon__partial_rounds_state1_cubed_1 + column8_row38 + column8_row38 + 3618502788666131213697322783095070105623107215331596699973092056135872020479 * poseidon__poseidon__partial_rounds_state1_cubed_2 + poseidon__poseidon__partial_round_key1).
              let val := addmod(
                /*column8_row54*/ mload(0x36a0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            addmod(
                              mulmod(
                                8,
                                /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_0*/ mload(0x4700),
                                PRIME),
                              mulmod(4, /*column8_row22*/ mload(0x3480), PRIME),
                              PRIME),
                            mulmod(
                              6,
                              /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_1*/ mload(0x4720),
                              PRIME),
                            PRIME),
                          /*column8_row38*/ mload(0x35a0),
                          PRIME),
                        /*column8_row38*/ mload(0x35a0),
                        PRIME),
                      mulmod(
                        3618502788666131213697322783095070105623107215331596699973092056135872020479,
                        /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_2*/ mload(0x4740),
                        PRIME),
                      PRIME),
                    /*periodic_column/poseidon/poseidon/partial_round_key1*/ mload(0x100),
                    PRIME)),
                PRIME)

              // Numerator: (point^(trace_length / 512) - trace_generator^(19 * trace_length / 32)) * (point^(trace_length / 512) - trace_generator^(21 * trace_length / 32)) * domain15 * domain17.
              // val *= domains[20].
              val := mulmod(val, /*domains[20]*/ mload(0x5100), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x53e0), PRIME)

              // res += val * coefficients[191].
              res := addmod(res,
                            mulmod(val, /*coefficients[191]*/ mload(0x1e20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_partial_to_full0: column8_row309 - (16 * poseidon__poseidon__partial_rounds_state1_cubed_19 + 8 * column8_row326 + 16 * poseidon__poseidon__partial_rounds_state1_cubed_20 + 6 * column8_row342 + poseidon__poseidon__partial_rounds_state1_cubed_21 + 560279373700919169769089400651532183647886248799764942664266404650165812023).
              let val := addmod(
                /*column8_row309*/ mload(0x3a80),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            mulmod(
                              16,
                              /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_19*/ mload(0x4760),
                              PRIME),
                            mulmod(8, /*column8_row326*/ mload(0x3ae0), PRIME),
                            PRIME),
                          mulmod(
                            16,
                            /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_20*/ mload(0x4780),
                            PRIME),
                          PRIME),
                        mulmod(6, /*column8_row342*/ mload(0x3b20), PRIME),
                        PRIME),
                      /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_21*/ mload(0x47a0),
                      PRIME),
                    560279373700919169769089400651532183647886248799764942664266404650165812023,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[192].
              res := addmod(res,
                            mulmod(val, /*coefficients[192]*/ mload(0x1e40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_partial_to_full1: column8_row269 - (4 * poseidon__poseidon__partial_rounds_state1_cubed_20 + column8_row342 + column8_row342 + poseidon__poseidon__partial_rounds_state1_cubed_21 + 1401754474293352309994371631695783042590401941592571735921592823982231996415).
              let val := addmod(
                /*column8_row269*/ mload(0x3a40),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            4,
                            /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_20*/ mload(0x4780),
                            PRIME),
                          /*column8_row342*/ mload(0x3b20),
                          PRIME),
                        /*column8_row342*/ mload(0x3b20),
                        PRIME),
                      /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_21*/ mload(0x47a0),
                      PRIME),
                    1401754474293352309994371631695783042590401941592571735921592823982231996415,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[193].
              res := addmod(res,
                            mulmod(val, /*coefficients[193]*/ mload(0x1e60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for poseidon/poseidon/margin_partial_to_full2: column8_row301 - (8 * poseidon__poseidon__partial_rounds_state1_cubed_19 + 4 * column8_row326 + 6 * poseidon__poseidon__partial_rounds_state1_cubed_20 + column8_row342 + column8_row342 + 3618502788666131213697322783095070105623107215331596699973092056135872020479 * poseidon__poseidon__partial_rounds_state1_cubed_21 + 1246177936547655338400308396717835700699368047388302793172818304164989556526).
              let val := addmod(
                /*column8_row301*/ mload(0x3a60),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            addmod(
                              mulmod(
                                8,
                                /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_19*/ mload(0x4760),
                                PRIME),
                              mulmod(4, /*column8_row326*/ mload(0x3ae0), PRIME),
                              PRIME),
                            mulmod(
                              6,
                              /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_20*/ mload(0x4780),
                              PRIME),
                            PRIME),
                          /*column8_row342*/ mload(0x3b20),
                          PRIME),
                        /*column8_row342*/ mload(0x3b20),
                        PRIME),
                      mulmod(
                        3618502788666131213697322783095070105623107215331596699973092056135872020479,
                        /*intermediate_value/poseidon/poseidon/partial_rounds_state1_cubed_21*/ mload(0x47a0),
                        PRIME),
                      PRIME),
                    1246177936547655338400308396717835700699368047388302793172818304164989556526,
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x5560), PRIME)

              // res += val * coefficients[194].
              res := addmod(res,
                            mulmod(val, /*coefficients[194]*/ mload(0x1e80), PRIME),
                            PRIME)
              }

            mstore(0, res)
            return(0, 0x20)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------