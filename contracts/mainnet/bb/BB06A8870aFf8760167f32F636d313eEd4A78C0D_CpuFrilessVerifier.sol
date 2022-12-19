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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract CairoVerifierContract {
    function verifyProofExternal(
        uint256[] calldata proofParams,
        uint256[] calldata proof,
        uint256[] calldata publicInput
    ) external virtual;

    /*
      Returns information that is related to the layout.

      publicMemoryOffset is the offset of the public memory pages' information in the public input.
      selectedBuiltins is a bit-map of builtins that are present in the layout.
    */
    function getLayoutInfo()
        external
        pure
        virtual
        returns (uint256 publicMemoryOffset, uint256 selectedBuiltins);

    uint256 internal constant OUTPUT_BUILTIN_BIT = 0;
    uint256 internal constant PEDERSEN_BUILTIN_BIT = 1;
    uint256 internal constant RANGE_CHECK_BUILTIN_BIT = 2;
    uint256 internal constant ECDSA_BUILTIN_BIT = 3;
    uint256 internal constant BITWISE_BUILTIN_BIT = 4;
    uint256 internal constant EC_OP_BUILTIN_BIT = 5;
}

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
    // [0x80, 0xa0) - trace_length.
    // [0xa0, 0xc0) - offset_size.
    // [0xc0, 0xe0) - half_offset_size.
    // [0xe0, 0x100) - initial_ap.
    // [0x100, 0x120) - initial_pc.
    // [0x120, 0x140) - final_ap.
    // [0x140, 0x160) - final_pc.
    // [0x160, 0x180) - memory/multi_column_perm/perm/interaction_elm.
    // [0x180, 0x1a0) - memory/multi_column_perm/hash_interaction_elm0.
    // [0x1a0, 0x1c0) - memory/multi_column_perm/perm/public_memory_prod.
    // [0x1c0, 0x1e0) - rc16/perm/interaction_elm.
    // [0x1e0, 0x200) - rc16/perm/public_memory_prod.
    // [0x200, 0x220) - rc_min.
    // [0x220, 0x240) - rc_max.
    // [0x240, 0x260) - diluted_check/permutation/interaction_elm.
    // [0x260, 0x280) - diluted_check/permutation/public_memory_prod.
    // [0x280, 0x2a0) - diluted_check/first_elm.
    // [0x2a0, 0x2c0) - diluted_check/interaction_z.
    // [0x2c0, 0x2e0) - diluted_check/interaction_alpha.
    // [0x2e0, 0x300) - diluted_check/final_cum_val.
    // [0x300, 0x320) - pedersen/shift_point.x.
    // [0x320, 0x340) - pedersen/shift_point.y.
    // [0x340, 0x360) - initial_pedersen_addr.
    // [0x360, 0x380) - initial_rc_addr.
    // [0x380, 0x3a0) - ecdsa/sig_config.alpha.
    // [0x3a0, 0x3c0) - ecdsa/sig_config.shift_point.x.
    // [0x3c0, 0x3e0) - ecdsa/sig_config.shift_point.y.
    // [0x3e0, 0x400) - ecdsa/sig_config.beta.
    // [0x400, 0x420) - initial_ecdsa_addr.
    // [0x420, 0x440) - initial_bitwise_addr.
    // [0x440, 0x460) - initial_ec_op_addr.
    // [0x460, 0x480) - ec_op/curve_config.alpha.
    // [0x480, 0x4a0) - trace_generator.
    // [0x4a0, 0x4c0) - oods_point.
    // [0x4c0, 0x580) - interaction_elements.
    // [0x580, 0x2240) - coefficients.
    // [0x2240, 0x4600) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x4600, 0x4620) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x4620, 0x4640) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x4640, 0x4660) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x4660, 0x4680) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x4680, 0x46a0) - intermediate_value/cpu/decode/flag_op1_base_op0_0.
    // [0x46a0, 0x46c0) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x46c0, 0x46e0) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x46e0, 0x4700) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x4700, 0x4720) - intermediate_value/cpu/decode/flag_res_op1_0.
    // [0x4720, 0x4740) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x4740, 0x4760) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x4760, 0x4780) - intermediate_value/cpu/decode/flag_pc_update_regular_0.
    // [0x4780, 0x47a0) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x47a0, 0x47c0) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x47c0, 0x47e0) - intermediate_value/cpu/decode/fp_update_regular_0.
    // [0x47e0, 0x4800) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x4800, 0x4820) - intermediate_value/npc_reg_0.
    // [0x4820, 0x4840) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x4840, 0x4860) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x4860, 0x4880) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x4880, 0x48a0) - intermediate_value/memory/address_diff_0.
    // [0x48a0, 0x48c0) - intermediate_value/rc16/diff_0.
    // [0x48c0, 0x48e0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x48e0, 0x4900) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x4900, 0x4920) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_0.
    // [0x4920, 0x4940) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0.
    // [0x4940, 0x4960) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_0.
    // [0x4960, 0x4980) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0.
    // [0x4980, 0x49a0) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_0.
    // [0x49a0, 0x49c0) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0.
    // [0x49c0, 0x49e0) - intermediate_value/rc_builtin/value0_0.
    // [0x49e0, 0x4a00) - intermediate_value/rc_builtin/value1_0.
    // [0x4a00, 0x4a20) - intermediate_value/rc_builtin/value2_0.
    // [0x4a20, 0x4a40) - intermediate_value/rc_builtin/value3_0.
    // [0x4a40, 0x4a60) - intermediate_value/rc_builtin/value4_0.
    // [0x4a60, 0x4a80) - intermediate_value/rc_builtin/value5_0.
    // [0x4a80, 0x4aa0) - intermediate_value/rc_builtin/value6_0.
    // [0x4aa0, 0x4ac0) - intermediate_value/rc_builtin/value7_0.
    // [0x4ac0, 0x4ae0) - intermediate_value/ecdsa/signature0/doubling_key/x_squared.
    // [0x4ae0, 0x4b00) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0.
    // [0x4b00, 0x4b20) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0.
    // [0x4b20, 0x4b40) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_0.
    // [0x4b40, 0x4b60) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0.
    // [0x4b60, 0x4b80) - intermediate_value/bitwise/sum_var_0_0.
    // [0x4b80, 0x4ba0) - intermediate_value/bitwise/sum_var_8_0.
    // [0x4ba0, 0x4bc0) - intermediate_value/ec_op/doubling_q/x_squared_0.
    // [0x4bc0, 0x4be0) - intermediate_value/ec_op/ec_subset_sum/bit_0.
    // [0x4be0, 0x4c00) - intermediate_value/ec_op/ec_subset_sum/bit_neg_0.
    // [0x4c00, 0x50a0) - expmods.
    // [0x50a0, 0x5420) - domains.
    // [0x5420, 0x5700) - denominator_invs.
    // [0x5700, 0x59e0) - denominators.
    // [0x59e0, 0x5aa0) - expmod_context.

    fallback() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x4600)
            let point := /*oods_point*/ mload(0x4a0)
            function expmod(base, exponent, modulus) -> result {
              let p := /*expmod_context*/ 0x59e0
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

              // expmods[0] = point^(trace_length / 8192).
              mstore(0x4c00, expmod(point, div(/*trace_length*/ mload(0x80), 8192), PRIME))

              // expmods[1] = point^(trace_length / 4096).
              mstore(0x4c20, mulmod(
                /*point^(trace_length / 8192)*/ mload(0x4c00),
                /*point^(trace_length / 8192)*/ mload(0x4c00),
                PRIME))

              // expmods[2] = point^(trace_length / 1024).
              mstore(0x4c40, expmod(point, div(/*trace_length*/ mload(0x80), 1024), PRIME))

              // expmods[3] = point^(trace_length / 512).
              mstore(0x4c60, mulmod(
                /*point^(trace_length / 1024)*/ mload(0x4c40),
                /*point^(trace_length / 1024)*/ mload(0x4c40),
                PRIME))

              // expmods[4] = point^(trace_length / 256).
              mstore(0x4c80, mulmod(
                /*point^(trace_length / 512)*/ mload(0x4c60),
                /*point^(trace_length / 512)*/ mload(0x4c60),
                PRIME))

              // expmods[5] = point^(trace_length / 128).
              mstore(0x4ca0, mulmod(
                /*point^(trace_length / 256)*/ mload(0x4c80),
                /*point^(trace_length / 256)*/ mload(0x4c80),
                PRIME))

              // expmods[6] = point^(trace_length / 32).
              mstore(0x4cc0, expmod(point, div(/*trace_length*/ mload(0x80), 32), PRIME))

              // expmods[7] = point^(trace_length / 16).
              mstore(0x4ce0, mulmod(
                /*point^(trace_length / 32)*/ mload(0x4cc0),
                /*point^(trace_length / 32)*/ mload(0x4cc0),
                PRIME))

              // expmods[8] = point^(trace_length / 2).
              mstore(0x4d00, expmod(point, div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[9] = point^trace_length.
              mstore(0x4d20, mulmod(
                /*point^(trace_length / 2)*/ mload(0x4d00),
                /*point^(trace_length / 2)*/ mload(0x4d00),
                PRIME))

              // expmods[10] = trace_generator^(trace_length / 64).
              mstore(0x4d40, expmod(/*trace_generator*/ mload(0x480), div(/*trace_length*/ mload(0x80), 64), PRIME))

              // expmods[11] = trace_generator^(trace_length / 32).
              mstore(0x4d60, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                PRIME))

              // expmods[12] = trace_generator^(3 * trace_length / 64).
              mstore(0x4d80, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(trace_length / 32)*/ mload(0x4d60),
                PRIME))

              // expmods[13] = trace_generator^(trace_length / 16).
              mstore(0x4da0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(3 * trace_length / 64)*/ mload(0x4d80),
                PRIME))

              // expmods[14] = trace_generator^(5 * trace_length / 64).
              mstore(0x4dc0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(trace_length / 16)*/ mload(0x4da0),
                PRIME))

              // expmods[15] = trace_generator^(3 * trace_length / 32).
              mstore(0x4de0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(5 * trace_length / 64)*/ mload(0x4dc0),
                PRIME))

              // expmods[16] = trace_generator^(7 * trace_length / 64).
              mstore(0x4e00, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(3 * trace_length / 32)*/ mload(0x4de0),
                PRIME))

              // expmods[17] = trace_generator^(trace_length / 8).
              mstore(0x4e20, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(7 * trace_length / 64)*/ mload(0x4e00),
                PRIME))

              // expmods[18] = trace_generator^(9 * trace_length / 64).
              mstore(0x4e40, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(trace_length / 8)*/ mload(0x4e20),
                PRIME))

              // expmods[19] = trace_generator^(5 * trace_length / 32).
              mstore(0x4e60, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(9 * trace_length / 64)*/ mload(0x4e40),
                PRIME))

              // expmods[20] = trace_generator^(11 * trace_length / 64).
              mstore(0x4e80, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(5 * trace_length / 32)*/ mload(0x4e60),
                PRIME))

              // expmods[21] = trace_generator^(3 * trace_length / 16).
              mstore(0x4ea0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(11 * trace_length / 64)*/ mload(0x4e80),
                PRIME))

              // expmods[22] = trace_generator^(13 * trace_length / 64).
              mstore(0x4ec0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(3 * trace_length / 16)*/ mload(0x4ea0),
                PRIME))

              // expmods[23] = trace_generator^(7 * trace_length / 32).
              mstore(0x4ee0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(13 * trace_length / 64)*/ mload(0x4ec0),
                PRIME))

              // expmods[24] = trace_generator^(15 * trace_length / 64).
              mstore(0x4f00, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(7 * trace_length / 32)*/ mload(0x4ee0),
                PRIME))

              // expmods[25] = trace_generator^(trace_length / 2).
              mstore(0x4f20, expmod(/*trace_generator*/ mload(0x480), div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[26] = trace_generator^(3 * trace_length / 4).
              mstore(0x4f40, expmod(/*trace_generator*/ mload(0x480), div(mul(3, /*trace_length*/ mload(0x80)), 4), PRIME))

              // expmods[27] = trace_generator^(15 * trace_length / 16).
              mstore(0x4f60, mulmod(
                /*trace_generator^(3 * trace_length / 16)*/ mload(0x4ea0),
                /*trace_generator^(3 * trace_length / 4)*/ mload(0x4f40),
                PRIME))

              // expmods[28] = trace_generator^(251 * trace_length / 256).
              mstore(0x4f80, expmod(/*trace_generator*/ mload(0x480), div(mul(251, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[29] = trace_generator^(63 * trace_length / 64).
              mstore(0x4fa0, mulmod(
                /*trace_generator^(3 * trace_length / 64)*/ mload(0x4d80),
                /*trace_generator^(15 * trace_length / 16)*/ mload(0x4f60),
                PRIME))

              // expmods[30] = trace_generator^(255 * trace_length / 256).
              mstore(0x4fc0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x4d40),
                /*trace_generator^(251 * trace_length / 256)*/ mload(0x4f80),
                PRIME))

              // expmods[31] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4fe0, expmod(/*trace_generator*/ mload(0x480), mul(16, sub(div(/*trace_length*/ mload(0x80), 16), 1)), PRIME))

              // expmods[32] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x5000, expmod(/*trace_generator*/ mload(0x480), mul(2, sub(div(/*trace_length*/ mload(0x80), 2), 1)), PRIME))

              // expmods[33] = trace_generator^(trace_length - 1).
              mstore(0x5020, expmod(/*trace_generator*/ mload(0x480), sub(/*trace_length*/ mload(0x80), 1), PRIME))

              // expmods[34] = trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x5040, expmod(/*trace_generator*/ mload(0x480), mul(128, sub(div(/*trace_length*/ mload(0x80), 128), 1)), PRIME))

              // expmods[35] = trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x5060, expmod(/*trace_generator*/ mload(0x480), mul(8192, sub(div(/*trace_length*/ mload(0x80), 8192), 1)), PRIME))

              // expmods[36] = trace_generator^(4096 * (trace_length / 4096 - 1)).
              mstore(0x5080, expmod(/*trace_generator*/ mload(0x480), mul(4096, sub(div(/*trace_length*/ mload(0x80), 4096), 1)), PRIME))

            }

            {
              // Compute domains.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'diluted_check/permutation/step0', 'diluted_check/step', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // domains[0] = point^trace_length - 1.
              mstore(0x50a0,
                     addmod(/*point^trace_length*/ mload(0x4d20), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func', 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // domains[1] = point^(trace_length / 2) - 1.
              mstore(0x50c0,
                     addmod(/*point^(trace_length / 2)*/ mload(0x4d00), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/zero'.
              // Numerator for constraints: 'cpu/decode/opcode_rc/bit'.
              // domains[2] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x50e0,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x4ce0),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x4f60)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/decode/flag_op1_base_op0_bit', 'cpu/decode/flag_res_op1_bit', 'cpu/decode/flag_pc_update_regular_bit', 'cpu/decode/fp_update_regular_bit', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/call/off0', 'cpu/opcodes/call/off1', 'cpu/opcodes/call/flags', 'cpu/opcodes/ret/off0', 'cpu/opcodes/ret/off2', 'cpu/opcodes/ret/flags', 'cpu/opcodes/assert_eq/assert_eq', 'public_memory_addr_zero', 'public_memory_value_zero', 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y', 'ec_op/doubling_q/slope', 'ec_op/doubling_q/x', 'ec_op/doubling_q/y', 'ec_op/ec_subset_sum/booleanity_test', 'ec_op/ec_subset_sum/add_points/slope', 'ec_op/ec_subset_sum/add_points/x', 'ec_op/ec_subset_sum/add_points/y', 'ec_op/ec_subset_sum/add_points/x_diff_inv', 'ec_op/ec_subset_sum/copy_point/x', 'ec_op/ec_subset_sum/copy_point/y'.
              // domains[3] = point^(trace_length / 16) - 1.
              mstore(0x5100,
                     addmod(/*point^(trace_length / 16)*/ mload(0x4ce0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // domains[4] = point^(trace_length / 32) - 1.
              mstore(0x5120,
                     addmod(/*point^(trace_length / 32)*/ mload(0x4cc0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/input0_addr', 'pedersen/input1_addr', 'pedersen/output_addr', 'rc_builtin/value', 'rc_builtin/addr_step'.
              // domains[5] = point^(trace_length / 128) - 1.
              mstore(0x5140,
                     addmod(/*point^(trace_length / 128)*/ mload(0x4ca0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // domains[6] = point^(trace_length / 256) - 1.
              mstore(0x5160,
                     addmod(/*point^(trace_length / 256)*/ mload(0x4c80), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail', 'pedersen/hash1/ec_subset_sum/zeros_tail', 'pedersen/hash2/ec_subset_sum/zeros_tail', 'pedersen/hash3/ec_subset_sum/zeros_tail'.
              // Numerator for constraints: 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // domains[7] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x5180,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x4c80),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4fc0)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end', 'pedersen/hash1/ec_subset_sum/bit_extraction_end', 'pedersen/hash2/ec_subset_sum/bit_extraction_end', 'pedersen/hash3/ec_subset_sum/bit_extraction_end'.
              // domains[8] = point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              mstore(0x51a0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x4c80),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4fa0)),
                       PRIME))

              // Numerator for constraints: 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // domains[9] = point^(trace_length / 512) - trace_generator^(trace_length / 2).
              mstore(0x51c0,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x4c60),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x4f20)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/hash1/init/x', 'pedersen/hash1/init/y', 'pedersen/hash2/init/x', 'pedersen/hash2/init/y', 'pedersen/hash3/init/x', 'pedersen/hash3/init/y', 'pedersen/input0_value0', 'pedersen/input0_value1', 'pedersen/input0_value2', 'pedersen/input0_value3', 'pedersen/input1_value0', 'pedersen/input1_value1', 'pedersen/input1_value2', 'pedersen/input1_value3', 'pedersen/output_value0', 'pedersen/output_value1', 'pedersen/output_value2', 'pedersen/output_value3'.
              // domains[10] = point^(trace_length / 512) - 1.
              mstore(0x51e0,
                     addmod(/*point^(trace_length / 512)*/ mload(0x4c60), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'bitwise/step_var_pool_addr', 'bitwise/partition'.
              // domains[11] = point^(trace_length / 1024) - 1.
              mstore(0x5200,
                     addmod(/*point^(trace_length / 1024)*/ mload(0x4c40), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/zeros_tail', 'ec_op/ec_subset_sum/zeros_tail'.
              // Numerator for constraints: 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y', 'ec_op/doubling_q/slope', 'ec_op/doubling_q/x', 'ec_op/doubling_q/y', 'ec_op/ec_subset_sum/booleanity_test', 'ec_op/ec_subset_sum/add_points/slope', 'ec_op/ec_subset_sum/add_points/x', 'ec_op/ec_subset_sum/add_points/y', 'ec_op/ec_subset_sum/add_points/x_diff_inv', 'ec_op/ec_subset_sum/copy_point/x', 'ec_op/ec_subset_sum/copy_point/y'.
              // domains[12] = point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              mstore(0x5220,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4c20),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4fc0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/bit_extraction_end'.
              // domains[13] = point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              mstore(0x5240,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4c20),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4f80)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y', 'ecdsa/signature0/r_and_w_nonzero', 'bitwise/x_or_y_addr', 'bitwise/next_var_pool_addr', 'bitwise/or_is_and_plus_xor', 'bitwise/unique_unpacking192', 'bitwise/unique_unpacking193', 'bitwise/unique_unpacking194', 'bitwise/unique_unpacking195', 'ec_op/p_x_addr', 'ec_op/p_y_addr', 'ec_op/q_x_addr', 'ec_op/q_y_addr', 'ec_op/m_addr', 'ec_op/r_x_addr', 'ec_op/r_y_addr', 'ec_op/get_q_x', 'ec_op/get_q_y', 'ec_op/ec_subset_sum/bit_unpacking/last_one_is_zero', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'ec_op/ec_subset_sum/bit_unpacking/cumulative_bit192', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'ec_op/ec_subset_sum/bit_unpacking/cumulative_bit196', 'ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'ec_op/get_m', 'ec_op/get_p_x', 'ec_op/get_p_y', 'ec_op/set_r_x', 'ec_op/set_r_y'.
              // domains[14] = point^(trace_length / 4096) - 1.
              mstore(0x5260,
                     addmod(/*point^(trace_length / 4096)*/ mload(0x4c20), sub(PRIME, 1), PRIME))

              // Numerator for constraints: 'bitwise/step_var_pool_addr'.
              // domains[15] = point^(trace_length / 4096) - trace_generator^(3 * trace_length / 4).
              mstore(0x5280,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4c20),
                       sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x4f40)),
                       PRIME))

              // Denominator for constraints: 'bitwise/addition_is_xor_with_and'.
              // domains[16] = (point^(trace_length / 4096) - trace_generator^(trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 8)) * (point^(trace_length / 4096) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(15 * trace_length / 64)) * domain14.
              {
                let domain := mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(trace_length / 64)*/ mload(0x4d40)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(trace_length / 32)*/ mload(0x4d60)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4c20),
                        sub(PRIME, /*trace_generator^(3 * trace_length / 64)*/ mload(0x4d80)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4c20),
                      sub(PRIME, /*trace_generator^(trace_length / 16)*/ mload(0x4da0)),
                      PRIME),
                    PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 64)*/ mload(0x4dc0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(3 * trace_length / 32)*/ mload(0x4de0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4c20),
                        sub(PRIME, /*trace_generator^(7 * trace_length / 64)*/ mload(0x4e00)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4c20),
                      sub(PRIME, /*trace_generator^(trace_length / 8)*/ mload(0x4e20)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(9 * trace_length / 64)*/ mload(0x4e40)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 32)*/ mload(0x4e60)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4c20),
                        sub(PRIME, /*trace_generator^(11 * trace_length / 64)*/ mload(0x4e80)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4c20),
                      sub(PRIME, /*trace_generator^(3 * trace_length / 16)*/ mload(0x4ea0)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(13 * trace_length / 64)*/ mload(0x4ec0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4c20),
                          sub(PRIME, /*trace_generator^(7 * trace_length / 32)*/ mload(0x4ee0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4c20),
                        sub(PRIME, /*trace_generator^(15 * trace_length / 64)*/ mload(0x4f00)),
                        PRIME),
                      PRIME),
                    /*domains[14]*/ mload(0x5260),
                    PRIME),
                  PRIME)
                mstore(0x52a0, domain)
              }

              // Denominator for constraints: 'ec_op/ec_subset_sum/bit_extraction_end'.
              // domains[17] = point^(trace_length / 4096) - trace_generator^(63 * trace_length / 64).
              mstore(0x52c0,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4c20),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4fa0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/zeros_tail'.
              // Numerator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // domains[18] = point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              mstore(0x52e0,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4c00),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4fc0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/bit_extraction_end'.
              // domains[19] = point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              mstore(0x5300,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4c00),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4f80)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve', 'ecdsa/message_addr', 'ecdsa/pubkey_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // domains[20] = point^(trace_length / 8192) - 1.
              mstore(0x5320,
                     addmod(/*point^(trace_length / 8192)*/ mload(0x4c00), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_fp', 'final_pc'.
              // Numerator for constraints: 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // domains[21] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x5340,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x4fe0)),
                       PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'memory/initial_addr', 'rc16/perm/init0', 'rc16/minimum', 'diluted_check/permutation/init0', 'diluted_check/init', 'diluted_check/first_element', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'bitwise/init_var_pool_addr', 'ec_op/init_addr'.
              // domains[22] = point - 1.
              mstore(0x5360,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last', 'rc16/perm/last', 'rc16/maximum'.
              // Numerator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func', 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // domains[23] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x5380,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x5000)),
                       PRIME))

              // Denominator for constraints: 'diluted_check/permutation/last', 'diluted_check/last'.
              // Numerator for constraints: 'diluted_check/permutation/step0', 'diluted_check/step'.
              // domains[24] = point - trace_generator^(trace_length - 1).
              mstore(0x53a0,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x5020)), PRIME))

              // Numerator for constraints: 'pedersen/input0_addr', 'rc_builtin/addr_step'.
              // domains[25] = point - trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x53c0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(128 * (trace_length / 128 - 1))*/ mload(0x5040)),
                       PRIME))

              // Numerator for constraints: 'ecdsa/pubkey_addr'.
              // domains[26] = point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x53e0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(8192 * (trace_length / 8192 - 1))*/ mload(0x5060)),
                       PRIME))

              // Numerator for constraints: 'bitwise/next_var_pool_addr', 'ec_op/p_x_addr'.
              // domains[27] = point - trace_generator^(4096 * (trace_length / 4096 - 1)).
              mstore(0x5400,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4096 * (trace_length / 4096 - 1))*/ mload(0x5080)),
                       PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // denominators[0] = domains[0].
              mstore(0x5700, /*domains[0]*/ mload(0x50a0))

              // denominators[1] = domains[2].
              mstore(0x5720, /*domains[2]*/ mload(0x50e0))

              // denominators[2] = domains[3].
              mstore(0x5740, /*domains[3]*/ mload(0x5100))

              // denominators[3] = domains[21].
              mstore(0x5760, /*domains[21]*/ mload(0x5340))

              // denominators[4] = domains[22].
              mstore(0x5780, /*domains[22]*/ mload(0x5360))

              // denominators[5] = domains[1].
              mstore(0x57a0, /*domains[1]*/ mload(0x50c0))

              // denominators[6] = domains[23].
              mstore(0x57c0, /*domains[23]*/ mload(0x5380))

              // denominators[7] = domains[24].
              mstore(0x57e0, /*domains[24]*/ mload(0x53a0))

              // denominators[8] = domains[6].
              mstore(0x5800, /*domains[6]*/ mload(0x5160))

              // denominators[9] = domains[7].
              mstore(0x5820, /*domains[7]*/ mload(0x5180))

              // denominators[10] = domains[8].
              mstore(0x5840, /*domains[8]*/ mload(0x51a0))

              // denominators[11] = domains[10].
              mstore(0x5860, /*domains[10]*/ mload(0x51e0))

              // denominators[12] = domains[5].
              mstore(0x5880, /*domains[5]*/ mload(0x5140))

              // denominators[13] = domains[12].
              mstore(0x58a0, /*domains[12]*/ mload(0x5220))

              // denominators[14] = domains[4].
              mstore(0x58c0, /*domains[4]*/ mload(0x5120))

              // denominators[15] = domains[18].
              mstore(0x58e0, /*domains[18]*/ mload(0x52e0))

              // denominators[16] = domains[19].
              mstore(0x5900, /*domains[19]*/ mload(0x5300))

              // denominators[17] = domains[13].
              mstore(0x5920, /*domains[13]*/ mload(0x5240))

              // denominators[18] = domains[20].
              mstore(0x5940, /*domains[20]*/ mload(0x5320))

              // denominators[19] = domains[14].
              mstore(0x5960, /*domains[14]*/ mload(0x5260))

              // denominators[20] = domains[11].
              mstore(0x5980, /*domains[11]*/ mload(0x5200))

              // denominators[21] = domains[16].
              mstore(0x59a0, /*domains[16]*/ mload(0x52a0))

              // denominators[22] = domains[17].
              mstore(0x59c0, /*domains[17]*/ mload(0x52c0))

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x2e0
              let prod := 1
              let partialProductEndPtr := 0x5700
              for { let partialProductPtr := 0x5420 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x5420
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
              let currentPartialProductPtr := 0x5700
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
                /*column0_row0*/ mload(0x2240),
                sub(
                  PRIME,
                  addmod(/*column0_row1*/ mload(0x2260), /*column0_row1*/ mload(0x2260), PRIME)),
                PRIME)
              mstore(0x4600, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column0_row2 - (column0_row3 + column0_row3).
              let val := addmod(
                /*column0_row2*/ mload(0x2280),
                sub(
                  PRIME,
                  addmod(/*column0_row3*/ mload(0x22a0), /*column0_row3*/ mload(0x22a0), PRIME)),
                PRIME)
              mstore(0x4620, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column0_row4 - (column0_row5 + column0_row5).
              let val := addmod(
                /*column0_row4*/ mload(0x22c0),
                sub(
                  PRIME,
                  addmod(/*column0_row5*/ mload(0x22e0), /*column0_row5*/ mload(0x22e0), PRIME)),
                PRIME)
              mstore(0x4640, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column0_row3 - (column0_row4 + column0_row4).
              let val := addmod(
                /*column0_row3*/ mload(0x22a0),
                sub(
                  PRIME,
                  addmod(/*column0_row4*/ mload(0x22c0), /*column0_row4*/ mload(0x22c0), PRIME)),
                PRIME)
              mstore(0x4660, val)
              }


              {
              // cpu/decode/flag_op1_base_op0_0 = 1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4620),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x4640),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x4660),
                    PRIME)),
                PRIME)
              mstore(0x4680, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column0_row5 - (column0_row6 + column0_row6).
              let val := addmod(
                /*column0_row5*/ mload(0x22e0),
                sub(
                  PRIME,
                  addmod(/*column0_row6*/ mload(0x2300), /*column0_row6*/ mload(0x2300), PRIME)),
                PRIME)
              mstore(0x46a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column0_row6 - (column0_row7 + column0_row7).
              let val := addmod(
                /*column0_row6*/ mload(0x2300),
                sub(
                  PRIME,
                  addmod(/*column0_row7*/ mload(0x2320), /*column0_row7*/ mload(0x2320), PRIME)),
                PRIME)
              mstore(0x46c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column0_row9 - (column0_row10 + column0_row10).
              let val := addmod(
                /*column0_row9*/ mload(0x2360),
                sub(
                  PRIME,
                  addmod(/*column0_row10*/ mload(0x2380), /*column0_row10*/ mload(0x2380), PRIME)),
                PRIME)
              mstore(0x46e0, val)
              }


              {
              // cpu/decode/flag_res_op1_0 = 1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x46a0),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x46c0),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0),
                    PRIME)),
                PRIME)
              mstore(0x4700, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column0_row7 - (column0_row8 + column0_row8).
              let val := addmod(
                /*column0_row7*/ mload(0x2320),
                sub(
                  PRIME,
                  addmod(/*column0_row8*/ mload(0x2340), /*column0_row8*/ mload(0x2340), PRIME)),
                PRIME)
              mstore(0x4720, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column0_row8 - (column0_row9 + column0_row9).
              let val := addmod(
                /*column0_row8*/ mload(0x2340),
                sub(
                  PRIME,
                  addmod(/*column0_row9*/ mload(0x2360), /*column0_row9*/ mload(0x2360), PRIME)),
                PRIME)
              mstore(0x4740, val)
              }


              {
              // cpu/decode/flag_pc_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4720),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4740),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0),
                    PRIME)),
                PRIME)
              mstore(0x4760, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column0_row12 - (column0_row13 + column0_row13).
              let val := addmod(
                /*column0_row12*/ mload(0x23c0),
                sub(
                  PRIME,
                  addmod(/*column0_row13*/ mload(0x23e0), /*column0_row13*/ mload(0x23e0), PRIME)),
                PRIME)
              mstore(0x4780, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column0_row13 - (column0_row14 + column0_row14).
              let val := addmod(
                /*column0_row13*/ mload(0x23e0),
                sub(
                  PRIME,
                  addmod(/*column0_row14*/ mload(0x2400), /*column0_row14*/ mload(0x2400), PRIME)),
                PRIME)
              mstore(0x47a0, val)
              }


              {
              // cpu/decode/fp_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x47a0),
                    PRIME)),
                PRIME)
              mstore(0x47c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column0_row1 - (column0_row2 + column0_row2).
              let val := addmod(
                /*column0_row1*/ mload(0x2260),
                sub(
                  PRIME,
                  addmod(/*column0_row2*/ mload(0x2280), /*column0_row2*/ mload(0x2280), PRIME)),
                PRIME)
              mstore(0x47e0, val)
              }


              {
              // npc_reg_0 = column19_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column19_row0*/ mload(0x3280),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4620),
                  PRIME),
                1,
                PRIME)
              mstore(0x4800, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column0_row10 - (column0_row11 + column0_row11).
              let val := addmod(
                /*column0_row10*/ mload(0x2380),
                sub(
                  PRIME,
                  addmod(/*column0_row11*/ mload(0x23a0), /*column0_row11*/ mload(0x23a0), PRIME)),
                PRIME)
              mstore(0x4820, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column0_row11 - (column0_row12 + column0_row12).
              let val := addmod(
                /*column0_row11*/ mload(0x23a0),
                sub(
                  PRIME,
                  addmod(/*column0_row12*/ mload(0x23c0), /*column0_row12*/ mload(0x23c0), PRIME)),
                PRIME)
              mstore(0x4840, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column0_row14 - (column0_row15 + column0_row15).
              let val := addmod(
                /*column0_row14*/ mload(0x2400),
                sub(
                  PRIME,
                  addmod(/*column0_row15*/ mload(0x2420), /*column0_row15*/ mload(0x2420), PRIME)),
                PRIME)
              mstore(0x4860, val)
              }


              {
              // memory/address_diff_0 = column20_row3 - column20_row1.
              let val := addmod(/*column20_row3*/ mload(0x3a40), sub(PRIME, /*column20_row1*/ mload(0x3a00)), PRIME)
              mstore(0x4880, val)
              }


              {
              // rc16/diff_0 = column21_row3 - column21_row1.
              let val := addmod(/*column21_row3*/ mload(0x3c00), sub(PRIME, /*column21_row1*/ mload(0x3bc0)), PRIME)
              mstore(0x48a0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column5_row0 - (column5_row1 + column5_row1).
              let val := addmod(
                /*column5_row0*/ mload(0x29a0),
                sub(
                  PRIME,
                  addmod(/*column5_row1*/ mload(0x29c0), /*column5_row1*/ mload(0x29c0), PRIME)),
                PRIME)
              mstore(0x48c0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0)),
                PRIME)
              mstore(0x48e0, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_0 = column8_row0 - (column8_row1 + column8_row1).
              let val := addmod(
                /*column8_row0*/ mload(0x2be0),
                sub(
                  PRIME,
                  addmod(/*column8_row1*/ mload(0x2c00), /*column8_row1*/ mload(0x2c00), PRIME)),
                PRIME)
              mstore(0x4900, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash1__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900)),
                PRIME)
              mstore(0x4920, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_0 = column11_row0 - (column11_row1 + column11_row1).
              let val := addmod(
                /*column11_row0*/ mload(0x2e20),
                sub(
                  PRIME,
                  addmod(/*column11_row1*/ mload(0x2e40), /*column11_row1*/ mload(0x2e40), PRIME)),
                PRIME)
              mstore(0x4940, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash2__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940)),
                PRIME)
              mstore(0x4960, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_0 = column14_row0 - (column14_row1 + column14_row1).
              let val := addmod(
                /*column14_row0*/ mload(0x3060),
                sub(
                  PRIME,
                  addmod(/*column14_row1*/ mload(0x3080), /*column14_row1*/ mload(0x3080), PRIME)),
                PRIME)
              mstore(0x4980, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash3__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980)),
                PRIME)
              mstore(0x49a0, val)
              }


              {
              // rc_builtin/value0_0 = column20_row12.
              let val := /*column20_row12*/ mload(0x3aa0)
              mstore(0x49c0, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column20_row28.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x49c0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row28*/ mload(0x3ac0),
                PRIME)
              mstore(0x49e0, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column20_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x49e0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row44*/ mload(0x3ae0),
                PRIME)
              mstore(0x4a00, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column20_row60.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x4a00),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row60*/ mload(0x3b00),
                PRIME)
              mstore(0x4a20, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column20_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x4a20),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row76*/ mload(0x3b20),
                PRIME)
              mstore(0x4a40, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column20_row92.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x4a40),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row92*/ mload(0x3b40),
                PRIME)
              mstore(0x4a60, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column20_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x4a60),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row108*/ mload(0x3b60),
                PRIME)
              mstore(0x4a80, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column20_row124.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x4a80),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row124*/ mload(0x3b80),
                PRIME)
              mstore(0x4aa0, val)
              }


              {
              // ecdsa/signature0/doubling_key/x_squared = column22_row6 * column22_row6.
              let val := mulmod(/*column22_row6*/ mload(0x3ce0), /*column22_row6*/ mload(0x3ce0), PRIME)
              mstore(0x4ac0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_0 = column23_row14 - (column23_row46 + column23_row46).
              let val := addmod(
                /*column23_row14*/ mload(0x4180),
                sub(
                  PRIME,
                  addmod(/*column23_row46*/ mload(0x4240), /*column23_row46*/ mload(0x4240), PRIME)),
                PRIME)
              mstore(0x4ae0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_generator__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0)),
                PRIME)
              mstore(0x4b00, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_0 = column22_row5 - (column22_row21 + column22_row21).
              let val := addmod(
                /*column22_row5*/ mload(0x3cc0),
                sub(
                  PRIME,
                  addmod(/*column22_row21*/ mload(0x3e80), /*column22_row21*/ mload(0x3e80), PRIME)),
                PRIME)
              mstore(0x4b20, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_key__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20)),
                PRIME)
              mstore(0x4b40, val)
              }


              {
              // bitwise/sum_var_0_0 = column1_row0 + column1_row64 * 2 + column1_row128 * 4 + column1_row192 * 8 + column1_row256 * 18446744073709551616 + column1_row320 * 36893488147419103232 + column1_row384 * 73786976294838206464 + column1_row448 * 147573952589676412928.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            /*column1_row0*/ mload(0x2440),
                            mulmod(/*column1_row64*/ mload(0x24a0), 2, PRIME),
                            PRIME),
                          mulmod(/*column1_row128*/ mload(0x24c0), 4, PRIME),
                          PRIME),
                        mulmod(/*column1_row192*/ mload(0x24e0), 8, PRIME),
                        PRIME),
                      mulmod(/*column1_row256*/ mload(0x2500), 18446744073709551616, PRIME),
                      PRIME),
                    mulmod(/*column1_row320*/ mload(0x2520), 36893488147419103232, PRIME),
                    PRIME),
                  mulmod(/*column1_row384*/ mload(0x2540), 73786976294838206464, PRIME),
                  PRIME),
                mulmod(/*column1_row448*/ mload(0x2560), 147573952589676412928, PRIME),
                PRIME)
              mstore(0x4b60, val)
              }


              {
              // bitwise/sum_var_8_0 = column1_row512 * 340282366920938463463374607431768211456 + column1_row576 * 680564733841876926926749214863536422912 + column1_row640 * 1361129467683753853853498429727072845824 + column1_row704 * 2722258935367507707706996859454145691648 + column1_row768 * 6277101735386680763835789423207666416102355444464034512896 + column1_row832 * 12554203470773361527671578846415332832204710888928069025792 + column1_row896 * 25108406941546723055343157692830665664409421777856138051584 + column1_row960 * 50216813883093446110686315385661331328818843555712276103168.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            mulmod(/*column1_row512*/ mload(0x2580), 340282366920938463463374607431768211456, PRIME),
                            mulmod(/*column1_row576*/ mload(0x25a0), 680564733841876926926749214863536422912, PRIME),
                            PRIME),
                          mulmod(/*column1_row640*/ mload(0x25c0), 1361129467683753853853498429727072845824, PRIME),
                          PRIME),
                        mulmod(/*column1_row704*/ mload(0x25e0), 2722258935367507707706996859454145691648, PRIME),
                        PRIME),
                      mulmod(
                        /*column1_row768*/ mload(0x2600),
                        6277101735386680763835789423207666416102355444464034512896,
                        PRIME),
                      PRIME),
                    mulmod(
                      /*column1_row832*/ mload(0x2620),
                      12554203470773361527671578846415332832204710888928069025792,
                      PRIME),
                    PRIME),
                  mulmod(
                    /*column1_row896*/ mload(0x2640),
                    25108406941546723055343157692830665664409421777856138051584,
                    PRIME),
                  PRIME),
                mulmod(
                  /*column1_row960*/ mload(0x2660),
                  50216813883093446110686315385661331328818843555712276103168,
                  PRIME),
                PRIME)
              mstore(0x4b80, val)
              }


              {
              // ec_op/doubling_q/x_squared_0 = column22_row13 * column22_row13.
              let val := mulmod(/*column22_row13*/ mload(0x3dc0), /*column22_row13*/ mload(0x3dc0), PRIME)
              mstore(0x4ba0, val)
              }


              {
              // ec_op/ec_subset_sum/bit_0 = column23_row0 - (column23_row16 + column23_row16).
              let val := addmod(
                /*column23_row0*/ mload(0x4080),
                sub(
                  PRIME,
                  addmod(/*column23_row16*/ mload(0x41a0), /*column23_row16*/ mload(0x41a0), PRIME)),
                PRIME)
              mstore(0x4bc0, val)
              }


              {
              // ec_op/ec_subset_sum/bit_neg_0 = 1 - ec_op__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0)),
                PRIME)
              mstore(0x4be0, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= domains[2].
              val := mulmod(val, /*domains[2]*/ mload(0x50e0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[0].
              res := addmod(res,
                            mulmod(val, /*coefficients[0]*/ mload(0x580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/zero: column0_row0.
              let val := /*column0_row0*/ mload(0x2240)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, /*denominator_invs[1]*/ mload(0x5440), PRIME)

              // res += val * coefficients[1].
              res := addmod(res,
                            mulmod(val, /*coefficients[1]*/ mload(0x5a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column19_row1 - (((column0_row0 * offset_size + column20_row4) * offset_size + column20_row8) * offset_size + column20_row0).
              let val := addmod(
                /*column19_row1*/ mload(0x32a0),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column0_row0*/ mload(0x2240), /*offset_size*/ mload(0xa0), PRIME),
                            /*column20_row4*/ mload(0x3a60),
                            PRIME),
                          /*offset_size*/ mload(0xa0),
                          PRIME),
                        /*column20_row8*/ mload(0x3a80),
                        PRIME),
                      /*offset_size*/ mload(0xa0),
                      PRIME),
                    /*column20_row0*/ mload(0x39e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[2].
              res := addmod(res,
                            mulmod(val, /*coefficients[2]*/ mload(0x5c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_op1_base_op0_bit: cpu__decode__flag_op1_base_op0_0 * cpu__decode__flag_op1_base_op0_0 - cpu__decode__flag_op1_base_op0_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x4680),
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x4680),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x4680)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[3].
              res := addmod(res,
                            mulmod(val, /*coefficients[3]*/ mload(0x5e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_res_op1_bit: cpu__decode__flag_res_op1_0 * cpu__decode__flag_res_op1_0 - cpu__decode__flag_res_op1_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4700),
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4700),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4700)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[4].
              res := addmod(res,
                            mulmod(val, /*coefficients[4]*/ mload(0x600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_pc_update_regular_bit: cpu__decode__flag_pc_update_regular_0 * cpu__decode__flag_pc_update_regular_0 - cpu__decode__flag_pc_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x4760),
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x4760),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x4760)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[5].
              res := addmod(res,
                            mulmod(val, /*coefficients[5]*/ mload(0x620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/fp_update_regular_bit: cpu__decode__fp_update_regular_0 * cpu__decode__fp_update_regular_0 - cpu__decode__fp_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x47c0),
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x47c0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x47c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[6].
              res := addmod(res,
                            mulmod(val, /*coefficients[6]*/ mload(0x640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column19_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column22_row8 + (1 - cpu__decode__opcode_rc__bit_0) * column22_row0 + column20_row0).
              let val := addmod(
                addmod(/*column19_row8*/ mload(0x3340), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600),
                        /*column22_row8*/ mload(0x3d20),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600)),
                          PRIME),
                        /*column22_row0*/ mload(0x3c20),
                        PRIME),
                      PRIME),
                    /*column20_row0*/ mload(0x39e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[7].
              res := addmod(res,
                            mulmod(val, /*coefficients[7]*/ mload(0x660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column19_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column22_row8 + (1 - cpu__decode__opcode_rc__bit_1) * column22_row0 + column20_row8).
              let val := addmod(
                addmod(/*column19_row4*/ mload(0x3300), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x47e0),
                        /*column22_row8*/ mload(0x3d20),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x47e0)),
                          PRIME),
                        /*column22_row0*/ mload(0x3c20),
                        PRIME),
                      PRIME),
                    /*column20_row8*/ mload(0x3a80),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[8].
              res := addmod(res,
                            mulmod(val, /*coefficients[8]*/ mload(0x680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column19_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column19_row0 + cpu__decode__opcode_rc__bit_4 * column22_row0 + cpu__decode__opcode_rc__bit_3 * column22_row8 + cpu__decode__flag_op1_base_op0_0 * column19_row5 + column20_row4).
              let val := addmod(
                addmod(/*column19_row12*/ mload(0x33c0), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4620),
                            /*column19_row0*/ mload(0x3280),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x4640),
                            /*column22_row0*/ mload(0x3c20),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x4660),
                          /*column22_row8*/ mload(0x3d20),
                          PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x4680),
                        /*column19_row5*/ mload(0x3320),
                        PRIME),
                      PRIME),
                    /*column20_row4*/ mload(0x3a60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[9].
              res := addmod(res,
                            mulmod(val, /*coefficients[9]*/ mload(0x6a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column22_row4 - column19_row5 * column19_row13.
              let val := addmod(
                /*column22_row4*/ mload(0x3ca0),
                sub(
                  PRIME,
                  mulmod(/*column19_row5*/ mload(0x3320), /*column19_row13*/ mload(0x33e0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[10].
              res := addmod(res,
                            mulmod(val, /*coefficients[10]*/ mload(0x6c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column22_row12 - (cpu__decode__opcode_rc__bit_5 * (column19_row5 + column19_row13) + cpu__decode__opcode_rc__bit_6 * column22_row4 + cpu__decode__flag_res_op1_0 * column19_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0)),
                    PRIME),
                  /*column22_row12*/ mload(0x3da0),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x46a0),
                        addmod(/*column19_row5*/ mload(0x3320), /*column19_row13*/ mload(0x33e0), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x46c0),
                        /*column22_row4*/ mload(0x3ca0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4700),
                      /*column19_row13*/ mload(0x33e0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[11].
              res := addmod(res,
                            mulmod(val, /*coefficients[11]*/ mload(0x6e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column22_row2 - cpu__decode__opcode_rc__bit_9 * column19_row9.
              let val := addmod(
                /*column22_row2*/ mload(0x3c60),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0),
                    /*column19_row9*/ mload(0x3360),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[12].
              res := addmod(res,
                            mulmod(val, /*coefficients[12]*/ mload(0x700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column22_row10 - column22_row2 * column22_row12.
              let val := addmod(
                /*column22_row10*/ mload(0x3d60),
                sub(
                  PRIME,
                  mulmod(/*column22_row2*/ mload(0x3c60), /*column22_row12*/ mload(0x3da0), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[13].
              res := addmod(res,
                            mulmod(val, /*coefficients[13]*/ mload(0x720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column19_row16 + column22_row2 * (column19_row16 - (column19_row0 + column19_row13)) - (cpu__decode__flag_pc_update_regular_0 * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column22_row12 + cpu__decode__opcode_rc__bit_8 * (column19_row0 + column22_row12)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0)),
                      PRIME),
                    /*column19_row16*/ mload(0x3400),
                    PRIME),
                  mulmod(
                    /*column22_row2*/ mload(0x3c60),
                    addmod(
                      /*column19_row16*/ mload(0x3400),
                      sub(
                        PRIME,
                        addmod(/*column19_row0*/ mload(0x3280), /*column19_row13*/ mload(0x33e0), PRIME)),
                      PRIME),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x4760),
                        /*intermediate_value/npc_reg_0*/ mload(0x4800),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4720),
                        /*column22_row12*/ mload(0x3da0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4740),
                      addmod(/*column19_row0*/ mload(0x3280), /*column22_row12*/ mload(0x3da0), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[14].
              res := addmod(res,
                            mulmod(val, /*coefficients[14]*/ mload(0x740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column22_row10 - cpu__decode__opcode_rc__bit_9) * (column19_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column22_row10*/ mload(0x3d60),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x46e0)),
                  PRIME),
                addmod(
                  /*column19_row16*/ mload(0x3400),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x4800)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[15].
              res := addmod(res,
                            mulmod(val, /*coefficients[15]*/ mload(0x760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column22_row16 - (column22_row0 + cpu__decode__opcode_rc__bit_10 * column22_row12 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column22_row16*/ mload(0x3e20),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column22_row0*/ mload(0x3c20),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x4820),
                          /*column22_row12*/ mload(0x3da0),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x4840),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[16].
              res := addmod(res,
                            mulmod(val, /*coefficients[16]*/ mload(0x780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column22_row24 - (cpu__decode__fp_update_regular_0 * column22_row8 + cpu__decode__opcode_rc__bit_13 * column19_row9 + cpu__decode__opcode_rc__bit_12 * (column22_row0 + 2)).
              let val := addmod(
                /*column22_row24*/ mload(0x3ee0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x47c0),
                        /*column22_row8*/ mload(0x3d20),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x47a0),
                        /*column19_row9*/ mload(0x3360),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                      addmod(/*column22_row0*/ mload(0x3c20), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[21].
              val := mulmod(val, /*domains[21]*/ mload(0x5340), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[17].
              res := addmod(res,
                            mulmod(val, /*coefficients[17]*/ mload(0x7a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column19_row9 - column22_row8).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                addmod(/*column19_row9*/ mload(0x3360), sub(PRIME, /*column22_row8*/ mload(0x3d20)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[18].
              res := addmod(res,
                            mulmod(val, /*coefficients[18]*/ mload(0x7c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column19_row5 - (column19_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                addmod(
                  /*column19_row5*/ mload(0x3320),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column19_row0*/ mload(0x3280),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x4620),
                        PRIME),
                      1,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[19].
              res := addmod(res,
                            mulmod(val, /*coefficients[19]*/ mload(0x7e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off0: cpu__decode__opcode_rc__bit_12 * (column20_row0 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                addmod(
                  /*column20_row0*/ mload(0x39e0),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[20].
              res := addmod(res,
                            mulmod(val, /*coefficients[20]*/ mload(0x800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off1: cpu__decode__opcode_rc__bit_12 * (column20_row8 - (half_offset_size + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                addmod(
                  /*column20_row8*/ mload(0x3a80),
                  sub(PRIME, addmod(/*half_offset_size*/ mload(0xc0), 1, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[21].
              res := addmod(res,
                            mulmod(val, /*coefficients[21]*/ mload(0x820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/flags: cpu__decode__opcode_rc__bit_12 * (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_12 + 1 + 1 - (cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_1 + 4)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4780),
                        PRIME),
                      1,
                      PRIME),
                    1,
                    PRIME),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x47e0),
                        PRIME),
                      4,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[22].
              res := addmod(res,
                            mulmod(val, /*coefficients[22]*/ mload(0x840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off0: cpu__decode__opcode_rc__bit_13 * (column20_row0 + 2 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x47a0),
                addmod(
                  addmod(/*column20_row0*/ mload(0x39e0), 2, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[23].
              res := addmod(res,
                            mulmod(val, /*coefficients[23]*/ mload(0x860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off2: cpu__decode__opcode_rc__bit_13 * (column20_row4 + 1 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x47a0),
                addmod(
                  addmod(/*column20_row4*/ mload(0x3a60), 1, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[24].
              res := addmod(res,
                            mulmod(val, /*coefficients[24]*/ mload(0x880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/flags: cpu__decode__opcode_rc__bit_13 * (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_3 + cpu__decode__flag_res_op1_0 - 4).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x47a0),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4720),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x4600),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x4660),
                      PRIME),
                    /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x4700),
                    PRIME),
                  sub(PRIME, 4),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[25].
              res := addmod(res,
                            mulmod(val, /*coefficients[25]*/ mload(0x8a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column19_row9 - column22_row12).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x4860),
                addmod(
                  /*column19_row9*/ mload(0x3360),
                  sub(PRIME, /*column22_row12*/ mload(0x3da0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[26].
              res := addmod(res,
                            mulmod(val, /*coefficients[26]*/ mload(0x8c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_ap: column22_row0 - initial_ap.
              let val := addmod(/*column22_row0*/ mload(0x3c20), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[27].
              res := addmod(res,
                            mulmod(val, /*coefficients[27]*/ mload(0x8e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_fp: column22_row8 - initial_ap.
              let val := addmod(/*column22_row8*/ mload(0x3d20), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[28].
              res := addmod(res,
                            mulmod(val, /*coefficients[28]*/ mload(0x900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_pc: column19_row0 - initial_pc.
              let val := addmod(/*column19_row0*/ mload(0x3280), sub(PRIME, /*initial_pc*/ mload(0x100)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[29].
              res := addmod(res,
                            mulmod(val, /*coefficients[29]*/ mload(0x920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_ap: column22_row0 - final_ap.
              let val := addmod(/*column22_row0*/ mload(0x3c20), sub(PRIME, /*final_ap*/ mload(0x120)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5480), PRIME)

              // res += val * coefficients[30].
              res := addmod(res,
                            mulmod(val, /*coefficients[30]*/ mload(0x940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_fp: column22_row8 - initial_ap.
              let val := addmod(/*column22_row8*/ mload(0x3d20), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5480), PRIME)

              // res += val * coefficients[31].
              res := addmod(res,
                            mulmod(val, /*coefficients[31]*/ mload(0x960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_pc: column19_row0 - final_pc.
              let val := addmod(/*column19_row0*/ mload(0x3280), sub(PRIME, /*final_pc*/ mload(0x140)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x5480), PRIME)

              // res += val * coefficients[32].
              res := addmod(res,
                            mulmod(val, /*coefficients[32]*/ mload(0x980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column20_row1 + memory/multi_column_perm/hash_interaction_elm0 * column21_row0)) * column26_inter1_row0 + column19_row0 + memory/multi_column_perm/hash_interaction_elm0 * column19_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                        sub(
                          PRIME,
                          addmod(
                            /*column20_row1*/ mload(0x3a00),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                              /*column21_row0*/ mload(0x3ba0),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column26_inter1_row0*/ mload(0x4580),
                      PRIME),
                    /*column19_row0*/ mload(0x3280),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                    /*column19_row1*/ mload(0x32a0),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[33].
              res := addmod(res,
                            mulmod(val, /*coefficients[33]*/ mload(0x9a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column20_row3 + memory/multi_column_perm/hash_interaction_elm0 * column21_row2)) * column26_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column19_row2 + memory/multi_column_perm/hash_interaction_elm0 * column19_row3)) * column26_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                    sub(
                      PRIME,
                      addmod(
                        /*column20_row3*/ mload(0x3a40),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                          /*column21_row2*/ mload(0x3be0),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column26_inter1_row2*/ mload(0x45c0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                      sub(
                        PRIME,
                        addmod(
                          /*column19_row2*/ mload(0x32c0),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                            /*column19_row3*/ mload(0x32e0),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column26_inter1_row0*/ mload(0x4580),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[23].
              val := mulmod(val, /*domains[23]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[34].
              res := addmod(res,
                            mulmod(val, /*coefficients[34]*/ mload(0x9c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column26_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column26_inter1_row0*/ mload(0x4580),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x1a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, /*denominator_invs[6]*/ mload(0x54e0), PRIME)

              // res += val * coefficients[35].
              res := addmod(res,
                            mulmod(val, /*coefficients[35]*/ mload(0x9e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x4880),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x4880),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x4880)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[23].
              val := mulmod(val, /*domains[23]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[36].
              res := addmod(res,
                            mulmod(val, /*coefficients[36]*/ mload(0xa00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column21_row0 - column21_row2).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x4880), sub(PRIME, 1), PRIME),
                addmod(/*column21_row0*/ mload(0x3ba0), sub(PRIME, /*column21_row2*/ mload(0x3be0)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[23].
              val := mulmod(val, /*domains[23]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[37].
              res := addmod(res,
                            mulmod(val, /*coefficients[37]*/ mload(0xa20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/initial_addr: column20_row1 - 1.
              let val := addmod(/*column20_row1*/ mload(0x3a00), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[38].
              res := addmod(res,
                            mulmod(val, /*coefficients[38]*/ mload(0xa40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column19_row2.
              let val := /*column19_row2*/ mload(0x32c0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[39].
              res := addmod(res,
                            mulmod(val, /*coefficients[39]*/ mload(0xa60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column19_row3.
              let val := /*column19_row3*/ mload(0x32e0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[40].
              res := addmod(res,
                            mulmod(val, /*coefficients[40]*/ mload(0xa80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column21_row1) * column26_inter1_row1 + column20_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column21_row1*/ mload(0x3bc0)),
                      PRIME),
                    /*column26_inter1_row1*/ mload(0x45a0),
                    PRIME),
                  /*column20_row0*/ mload(0x39e0),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x1c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[41].
              res := addmod(res,
                            mulmod(val, /*coefficients[41]*/ mload(0xaa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column21_row3) * column26_inter1_row3 - (rc16/perm/interaction_elm - column20_row2) * column26_inter1_row1.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x1c0),
                    sub(PRIME, /*column21_row3*/ mload(0x3c00)),
                    PRIME),
                  /*column26_inter1_row3*/ mload(0x45e0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column20_row2*/ mload(0x3a20)),
                      PRIME),
                    /*column26_inter1_row1*/ mload(0x45a0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[23].
              val := mulmod(val, /*domains[23]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[42].
              res := addmod(res,
                            mulmod(val, /*coefficients[42]*/ mload(0xac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column26_inter1_row1 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column26_inter1_row1*/ mload(0x45a0),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x1e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, /*denominator_invs[6]*/ mload(0x54e0), PRIME)

              // res += val * coefficients[43].
              res := addmod(res,
                            mulmod(val, /*coefficients[43]*/ mload(0xae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x48a0),
                  /*intermediate_value/rc16/diff_0*/ mload(0x48a0),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x48a0)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[23].
              val := mulmod(val, /*domains[23]*/ mload(0x5380), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x54c0), PRIME)

              // res += val * coefficients[44].
              res := addmod(res,
                            mulmod(val, /*coefficients[44]*/ mload(0xb00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column21_row1 - rc_min.
              let val := addmod(/*column21_row1*/ mload(0x3bc0), sub(PRIME, /*rc_min*/ mload(0x200)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[45].
              res := addmod(res,
                            mulmod(val, /*coefficients[45]*/ mload(0xb20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column21_row1 - rc_max.
              let val := addmod(/*column21_row1*/ mload(0x3bc0), sub(PRIME, /*rc_max*/ mload(0x220)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, /*denominator_invs[6]*/ mload(0x54e0), PRIME)

              // res += val * coefficients[46].
              res := addmod(res,
                            mulmod(val, /*coefficients[46]*/ mload(0xb40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/init0: (diluted_check/permutation/interaction_elm - column2_row0) * column25_inter1_row0 + column1_row0 - diluted_check/permutation/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                      sub(PRIME, /*column2_row0*/ mload(0x2840)),
                      PRIME),
                    /*column25_inter1_row0*/ mload(0x4540),
                    PRIME),
                  /*column1_row0*/ mload(0x2440),
                  PRIME),
                sub(PRIME, /*diluted_check/permutation/interaction_elm*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[47].
              res := addmod(res,
                            mulmod(val, /*coefficients[47]*/ mload(0xb60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/step0: (diluted_check/permutation/interaction_elm - column2_row1) * column25_inter1_row1 - (diluted_check/permutation/interaction_elm - column1_row1) * column25_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                    sub(PRIME, /*column2_row1*/ mload(0x2860)),
                    PRIME),
                  /*column25_inter1_row1*/ mload(0x4560),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                      sub(PRIME, /*column1_row1*/ mload(0x2460)),
                      PRIME),
                    /*column25_inter1_row0*/ mload(0x4540),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x53a0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[48].
              res := addmod(res,
                            mulmod(val, /*coefficients[48]*/ mload(0xb80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/last: column25_inter1_row0 - diluted_check/permutation/public_memory_prod.
              let val := addmod(
                /*column25_inter1_row0*/ mload(0x4540),
                sub(PRIME, /*diluted_check/permutation/public_memory_prod*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5500), PRIME)

              // res += val * coefficients[49].
              res := addmod(res,
                            mulmod(val, /*coefficients[49]*/ mload(0xba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/init: column24_inter1_row0 - 1.
              let val := addmod(/*column24_inter1_row0*/ mload(0x4500), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[50].
              res := addmod(res,
                            mulmod(val, /*coefficients[50]*/ mload(0xbc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/first_element: column2_row0 - diluted_check/first_elm.
              let val := addmod(
                /*column2_row0*/ mload(0x2840),
                sub(PRIME, /*diluted_check/first_elm*/ mload(0x280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[51].
              res := addmod(res,
                            mulmod(val, /*coefficients[51]*/ mload(0xbe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/step: column24_inter1_row1 - (column24_inter1_row0 * (1 + diluted_check/interaction_z * (column2_row1 - column2_row0)) + diluted_check/interaction_alpha * (column2_row1 - column2_row0) * (column2_row1 - column2_row0)).
              let val := addmod(
                /*column24_inter1_row1*/ mload(0x4520),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      /*column24_inter1_row0*/ mload(0x4500),
                      addmod(
                        1,
                        mulmod(
                          /*diluted_check/interaction_z*/ mload(0x2a0),
                          addmod(/*column2_row1*/ mload(0x2860), sub(PRIME, /*column2_row0*/ mload(0x2840)), PRIME),
                          PRIME),
                        PRIME),
                      PRIME),
                    mulmod(
                      mulmod(
                        /*diluted_check/interaction_alpha*/ mload(0x2c0),
                        addmod(/*column2_row1*/ mload(0x2860), sub(PRIME, /*column2_row0*/ mload(0x2840)), PRIME),
                        PRIME),
                      addmod(/*column2_row1*/ mload(0x2860), sub(PRIME, /*column2_row0*/ mload(0x2840)), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= domains[24].
              val := mulmod(val, /*domains[24]*/ mload(0x53a0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[52].
              res := addmod(res,
                            mulmod(val, /*coefficients[52]*/ mload(0xc00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/last: column24_inter1_row0 - diluted_check/final_cum_val.
              let val := addmod(
                /*column24_inter1_row0*/ mload(0x4500),
                sub(PRIME, /*diluted_check/final_cum_val*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x5500), PRIME)

              // res += val * coefficients[53].
              res := addmod(res,
                            mulmod(val, /*coefficients[53]*/ mload(0xc20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero: column16_row255 * (column5_row0 - (column5_row1 + column5_row1)).
              let val := mulmod(
                /*column16_row255*/ mload(0x31e0),
                addmod(
                  /*column5_row0*/ mload(0x29a0),
                  sub(
                    PRIME,
                    addmod(/*column5_row1*/ mload(0x29c0), /*column5_row1*/ mload(0x29c0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[54].
              res := addmod(res,
                            mulmod(val, /*coefficients[54]*/ mload(0xc40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column16_row255 * (column5_row1 - 3138550867693340381917894711603833208051177722232017256448 * column5_row192).
              let val := mulmod(
                /*column16_row255*/ mload(0x31e0),
                addmod(
                  /*column5_row1*/ mload(0x29c0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column5_row192*/ mload(0x29e0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[55].
              res := addmod(res,
                            mulmod(val, /*coefficients[55]*/ mload(0xc60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192: column16_row255 - column15_row255 * (column5_row192 - (column5_row193 + column5_row193)).
              let val := addmod(
                /*column16_row255*/ mload(0x31e0),
                sub(
                  PRIME,
                  mulmod(
                    /*column15_row255*/ mload(0x31a0),
                    addmod(
                      /*column5_row192*/ mload(0x29e0),
                      sub(
                        PRIME,
                        addmod(/*column5_row193*/ mload(0x2a00), /*column5_row193*/ mload(0x2a00), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[56].
              res := addmod(res,
                            mulmod(val, /*coefficients[56]*/ mload(0xc80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column15_row255 * (column5_row193 - 8 * column5_row196).
              let val := mulmod(
                /*column15_row255*/ mload(0x31a0),
                addmod(
                  /*column5_row193*/ mload(0x2a00),
                  sub(PRIME, mulmod(8, /*column5_row196*/ mload(0x2a20), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[57].
              res := addmod(res,
                            mulmod(val, /*coefficients[57]*/ mload(0xca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196: column15_row255 - (column5_row251 - (column5_row252 + column5_row252)) * (column5_row196 - (column5_row197 + column5_row197)).
              let val := addmod(
                /*column15_row255*/ mload(0x31a0),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column5_row251*/ mload(0x2a60),
                      sub(
                        PRIME,
                        addmod(/*column5_row252*/ mload(0x2a80), /*column5_row252*/ mload(0x2a80), PRIME)),
                      PRIME),
                    addmod(
                      /*column5_row196*/ mload(0x2a20),
                      sub(
                        PRIME,
                        addmod(/*column5_row197*/ mload(0x2a40), /*column5_row197*/ mload(0x2a40), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[58].
              res := addmod(res,
                            mulmod(val, /*coefficients[58]*/ mload(0xcc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column5_row251 - (column5_row252 + column5_row252)) * (column5_row197 - 18014398509481984 * column5_row251).
              let val := mulmod(
                addmod(
                  /*column5_row251*/ mload(0x2a60),
                  sub(
                    PRIME,
                    addmod(/*column5_row252*/ mload(0x2a80), /*column5_row252*/ mload(0x2a80), PRIME)),
                  PRIME),
                addmod(
                  /*column5_row197*/ mload(0x2a40),
                  sub(PRIME, mulmod(18014398509481984, /*column5_row251*/ mload(0x2a60), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[59].
              res := addmod(res,
                            mulmod(val, /*coefficients[59]*/ mload(0xce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[60].
              res := addmod(res,
                            mulmod(val, /*coefficients[60]*/ mload(0xd00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column5_row0.
              let val := /*column5_row0*/ mload(0x29a0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x5560), PRIME)

              // res += val * coefficients[61].
              res := addmod(res,
                            mulmod(val, /*coefficients[61]*/ mload(0xd20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column5_row0.
              let val := /*column5_row0*/ mload(0x29a0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x5540), PRIME)

              // res += val * coefficients[62].
              res := addmod(res,
                            mulmod(val, /*coefficients[62]*/ mload(0xd40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 - pedersen__points__y) - column15_row0 * (column3_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0),
                  addmod(
                    /*column4_row0*/ mload(0x2920),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column15_row0*/ mload(0x3180),
                    addmod(
                      /*column3_row0*/ mload(0x2880),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[63].
              res := addmod(res,
                            mulmod(val, /*coefficients[63]*/ mload(0xd60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column15_row0 * column15_row0 - pedersen__hash0__ec_subset_sum__bit_0 * (column3_row0 + pedersen__points__x + column3_row1).
              let val := addmod(
                mulmod(/*column15_row0*/ mload(0x3180), /*column15_row0*/ mload(0x3180), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0),
                    addmod(
                      addmod(
                        /*column3_row0*/ mload(0x2880),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column3_row1*/ mload(0x28a0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[64].
              res := addmod(res,
                            mulmod(val, /*coefficients[64]*/ mload(0xd80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 + column4_row1) - column15_row0 * (column3_row0 - column3_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x48c0),
                  addmod(/*column4_row0*/ mload(0x2920), /*column4_row1*/ mload(0x2940), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column15_row0*/ mload(0x3180),
                    addmod(/*column3_row0*/ mload(0x2880), sub(PRIME, /*column3_row1*/ mload(0x28a0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[65].
              res := addmod(res,
                            mulmod(val, /*coefficients[65]*/ mload(0xda0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column3_row1 - column3_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x48e0),
                addmod(/*column3_row1*/ mload(0x28a0), sub(PRIME, /*column3_row0*/ mload(0x2880)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[66].
              res := addmod(res,
                            mulmod(val, /*coefficients[66]*/ mload(0xdc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column4_row1 - column4_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x48e0),
                addmod(/*column4_row1*/ mload(0x2940), sub(PRIME, /*column4_row0*/ mload(0x2920)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[67].
              res := addmod(res,
                            mulmod(val, /*coefficients[67]*/ mload(0xde0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column3_row256 - column3_row255.
              let val := addmod(
                /*column3_row256*/ mload(0x28e0),
                sub(PRIME, /*column3_row255*/ mload(0x28c0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[68].
              res := addmod(res,
                            mulmod(val, /*coefficients[68]*/ mload(0xe00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column4_row256 - column4_row255.
              let val := addmod(
                /*column4_row256*/ mload(0x2980),
                sub(PRIME, /*column4_row255*/ mload(0x2960)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[69].
              res := addmod(res,
                            mulmod(val, /*coefficients[69]*/ mload(0xe20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column3_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column3_row0*/ mload(0x2880),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[70].
              res := addmod(res,
                            mulmod(val, /*coefficients[70]*/ mload(0xe40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column4_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column4_row0*/ mload(0x2920),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[71].
              res := addmod(res,
                            mulmod(val, /*coefficients[71]*/ mload(0xe60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/last_one_is_zero: column18_row255 * (column8_row0 - (column8_row1 + column8_row1)).
              let val := mulmod(
                /*column18_row255*/ mload(0x3260),
                addmod(
                  /*column8_row0*/ mload(0x2be0),
                  sub(
                    PRIME,
                    addmod(/*column8_row1*/ mload(0x2c00), /*column8_row1*/ mload(0x2c00), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[72].
              res := addmod(res,
                            mulmod(val, /*coefficients[72]*/ mload(0xe80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column18_row255 * (column8_row1 - 3138550867693340381917894711603833208051177722232017256448 * column8_row192).
              let val := mulmod(
                /*column18_row255*/ mload(0x3260),
                addmod(
                  /*column8_row1*/ mload(0x2c00),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column8_row192*/ mload(0x2c20),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[73].
              res := addmod(res,
                            mulmod(val, /*coefficients[73]*/ mload(0xea0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit192: column18_row255 - column17_row255 * (column8_row192 - (column8_row193 + column8_row193)).
              let val := addmod(
                /*column18_row255*/ mload(0x3260),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row255*/ mload(0x3220),
                    addmod(
                      /*column8_row192*/ mload(0x2c20),
                      sub(
                        PRIME,
                        addmod(/*column8_row193*/ mload(0x2c40), /*column8_row193*/ mload(0x2c40), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[74].
              res := addmod(res,
                            mulmod(val, /*coefficients[74]*/ mload(0xec0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column17_row255 * (column8_row193 - 8 * column8_row196).
              let val := mulmod(
                /*column17_row255*/ mload(0x3220),
                addmod(
                  /*column8_row193*/ mload(0x2c40),
                  sub(PRIME, mulmod(8, /*column8_row196*/ mload(0x2c60), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[75].
              res := addmod(res,
                            mulmod(val, /*coefficients[75]*/ mload(0xee0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit196: column17_row255 - (column8_row251 - (column8_row252 + column8_row252)) * (column8_row196 - (column8_row197 + column8_row197)).
              let val := addmod(
                /*column17_row255*/ mload(0x3220),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column8_row251*/ mload(0x2ca0),
                      sub(
                        PRIME,
                        addmod(/*column8_row252*/ mload(0x2cc0), /*column8_row252*/ mload(0x2cc0), PRIME)),
                      PRIME),
                    addmod(
                      /*column8_row196*/ mload(0x2c60),
                      sub(
                        PRIME,
                        addmod(/*column8_row197*/ mload(0x2c80), /*column8_row197*/ mload(0x2c80), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[76].
              res := addmod(res,
                            mulmod(val, /*coefficients[76]*/ mload(0xf00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column8_row251 - (column8_row252 + column8_row252)) * (column8_row197 - 18014398509481984 * column8_row251).
              let val := mulmod(
                addmod(
                  /*column8_row251*/ mload(0x2ca0),
                  sub(
                    PRIME,
                    addmod(/*column8_row252*/ mload(0x2cc0), /*column8_row252*/ mload(0x2cc0), PRIME)),
                  PRIME),
                addmod(
                  /*column8_row197*/ mload(0x2c80),
                  sub(PRIME, mulmod(18014398509481984, /*column8_row251*/ mload(0x2ca0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[77].
              res := addmod(res,
                            mulmod(val, /*coefficients[77]*/ mload(0xf20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/booleanity_test: pedersen__hash1__ec_subset_sum__bit_0 * (pedersen__hash1__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900),
                addmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[78].
              res := addmod(res,
                            mulmod(val, /*coefficients[78]*/ mload(0xf40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_extraction_end: column8_row0.
              let val := /*column8_row0*/ mload(0x2be0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x5560), PRIME)

              // res += val * coefficients[79].
              res := addmod(res,
                            mulmod(val, /*coefficients[79]*/ mload(0xf60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/zeros_tail: column8_row0.
              let val := /*column8_row0*/ mload(0x2be0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x5540), PRIME)

              // res += val * coefficients[80].
              res := addmod(res,
                            mulmod(val, /*coefficients[80]*/ mload(0xf80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/slope: pedersen__hash1__ec_subset_sum__bit_0 * (column7_row0 - pedersen__points__y) - column16_row0 * (column6_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900),
                  addmod(
                    /*column7_row0*/ mload(0x2b60),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column16_row0*/ mload(0x31c0),
                    addmod(
                      /*column6_row0*/ mload(0x2ac0),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[81].
              res := addmod(res,
                            mulmod(val, /*coefficients[81]*/ mload(0xfa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/x: column16_row0 * column16_row0 - pedersen__hash1__ec_subset_sum__bit_0 * (column6_row0 + pedersen__points__x + column6_row1).
              let val := addmod(
                mulmod(/*column16_row0*/ mload(0x31c0), /*column16_row0*/ mload(0x31c0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900),
                    addmod(
                      addmod(
                        /*column6_row0*/ mload(0x2ac0),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column6_row1*/ mload(0x2ae0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[82].
              res := addmod(res,
                            mulmod(val, /*coefficients[82]*/ mload(0xfc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/y: pedersen__hash1__ec_subset_sum__bit_0 * (column7_row0 + column7_row1) - column16_row0 * (column6_row0 - column6_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x4900),
                  addmod(/*column7_row0*/ mload(0x2b60), /*column7_row1*/ mload(0x2b80), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column16_row0*/ mload(0x31c0),
                    addmod(/*column6_row0*/ mload(0x2ac0), sub(PRIME, /*column6_row1*/ mload(0x2ae0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[83].
              res := addmod(res,
                            mulmod(val, /*coefficients[83]*/ mload(0xfe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/x: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column6_row1 - column6_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4920),
                addmod(/*column6_row1*/ mload(0x2ae0), sub(PRIME, /*column6_row0*/ mload(0x2ac0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[84].
              res := addmod(res,
                            mulmod(val, /*coefficients[84]*/ mload(0x1000), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/y: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column7_row1 - column7_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4920),
                addmod(/*column7_row1*/ mload(0x2b80), sub(PRIME, /*column7_row0*/ mload(0x2b60)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[85].
              res := addmod(res,
                            mulmod(val, /*coefficients[85]*/ mload(0x1020), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/x: column6_row256 - column6_row255.
              let val := addmod(
                /*column6_row256*/ mload(0x2b20),
                sub(PRIME, /*column6_row255*/ mload(0x2b00)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[86].
              res := addmod(res,
                            mulmod(val, /*coefficients[86]*/ mload(0x1040), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/y: column7_row256 - column7_row255.
              let val := addmod(
                /*column7_row256*/ mload(0x2bc0),
                sub(PRIME, /*column7_row255*/ mload(0x2ba0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[87].
              res := addmod(res,
                            mulmod(val, /*coefficients[87]*/ mload(0x1060), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/x: column6_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column6_row0*/ mload(0x2ac0),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[88].
              res := addmod(res,
                            mulmod(val, /*coefficients[88]*/ mload(0x1080), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/y: column7_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column7_row0*/ mload(0x2b60),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[89].
              res := addmod(res,
                            mulmod(val, /*coefficients[89]*/ mload(0x10a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/last_one_is_zero: column23_row145 * (column11_row0 - (column11_row1 + column11_row1)).
              let val := mulmod(
                /*column23_row145*/ mload(0x42a0),
                addmod(
                  /*column11_row0*/ mload(0x2e20),
                  sub(
                    PRIME,
                    addmod(/*column11_row1*/ mload(0x2e40), /*column11_row1*/ mload(0x2e40), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[90].
              res := addmod(res,
                            mulmod(val, /*coefficients[90]*/ mload(0x10c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column23_row145 * (column11_row1 - 3138550867693340381917894711603833208051177722232017256448 * column11_row192).
              let val := mulmod(
                /*column23_row145*/ mload(0x42a0),
                addmod(
                  /*column11_row1*/ mload(0x2e40),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column11_row192*/ mload(0x2e60),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[91].
              res := addmod(res,
                            mulmod(val, /*coefficients[91]*/ mload(0x10e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit192: column23_row145 - column23_row17 * (column11_row192 - (column11_row193 + column11_row193)).
              let val := addmod(
                /*column23_row145*/ mload(0x42a0),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row17*/ mload(0x41c0),
                    addmod(
                      /*column11_row192*/ mload(0x2e60),
                      sub(
                        PRIME,
                        addmod(/*column11_row193*/ mload(0x2e80), /*column11_row193*/ mload(0x2e80), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[92].
              res := addmod(res,
                            mulmod(val, /*coefficients[92]*/ mload(0x1100), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column23_row17 * (column11_row193 - 8 * column11_row196).
              let val := mulmod(
                /*column23_row17*/ mload(0x41c0),
                addmod(
                  /*column11_row193*/ mload(0x2e80),
                  sub(PRIME, mulmod(8, /*column11_row196*/ mload(0x2ea0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[93].
              res := addmod(res,
                            mulmod(val, /*coefficients[93]*/ mload(0x1120), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit196: column23_row17 - (column11_row251 - (column11_row252 + column11_row252)) * (column11_row196 - (column11_row197 + column11_row197)).
              let val := addmod(
                /*column23_row17*/ mload(0x41c0),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column11_row251*/ mload(0x2ee0),
                      sub(
                        PRIME,
                        addmod(/*column11_row252*/ mload(0x2f00), /*column11_row252*/ mload(0x2f00), PRIME)),
                      PRIME),
                    addmod(
                      /*column11_row196*/ mload(0x2ea0),
                      sub(
                        PRIME,
                        addmod(/*column11_row197*/ mload(0x2ec0), /*column11_row197*/ mload(0x2ec0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[94].
              res := addmod(res,
                            mulmod(val, /*coefficients[94]*/ mload(0x1140), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column11_row251 - (column11_row252 + column11_row252)) * (column11_row197 - 18014398509481984 * column11_row251).
              let val := mulmod(
                addmod(
                  /*column11_row251*/ mload(0x2ee0),
                  sub(
                    PRIME,
                    addmod(/*column11_row252*/ mload(0x2f00), /*column11_row252*/ mload(0x2f00), PRIME)),
                  PRIME),
                addmod(
                  /*column11_row197*/ mload(0x2ec0),
                  sub(PRIME, mulmod(18014398509481984, /*column11_row251*/ mload(0x2ee0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[95].
              res := addmod(res,
                            mulmod(val, /*coefficients[95]*/ mload(0x1160), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/booleanity_test: pedersen__hash2__ec_subset_sum__bit_0 * (pedersen__hash2__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940),
                addmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[96].
              res := addmod(res,
                            mulmod(val, /*coefficients[96]*/ mload(0x1180), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_extraction_end: column11_row0.
              let val := /*column11_row0*/ mload(0x2e20)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x5560), PRIME)

              // res += val * coefficients[97].
              res := addmod(res,
                            mulmod(val, /*coefficients[97]*/ mload(0x11a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/zeros_tail: column11_row0.
              let val := /*column11_row0*/ mload(0x2e20)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x5540), PRIME)

              // res += val * coefficients[98].
              res := addmod(res,
                            mulmod(val, /*coefficients[98]*/ mload(0x11c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/slope: pedersen__hash2__ec_subset_sum__bit_0 * (column10_row0 - pedersen__points__y) - column17_row0 * (column9_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940),
                  addmod(
                    /*column10_row0*/ mload(0x2da0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x3200),
                    addmod(
                      /*column9_row0*/ mload(0x2d00),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[99].
              res := addmod(res,
                            mulmod(val, /*coefficients[99]*/ mload(0x11e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/x: column17_row0 * column17_row0 - pedersen__hash2__ec_subset_sum__bit_0 * (column9_row0 + pedersen__points__x + column9_row1).
              let val := addmod(
                mulmod(/*column17_row0*/ mload(0x3200), /*column17_row0*/ mload(0x3200), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940),
                    addmod(
                      addmod(
                        /*column9_row0*/ mload(0x2d00),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column9_row1*/ mload(0x2d20),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[100].
              res := addmod(res,
                            mulmod(val, /*coefficients[100]*/ mload(0x1200), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/y: pedersen__hash2__ec_subset_sum__bit_0 * (column10_row0 + column10_row1) - column17_row0 * (column9_row0 - column9_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4940),
                  addmod(/*column10_row0*/ mload(0x2da0), /*column10_row1*/ mload(0x2dc0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x3200),
                    addmod(/*column9_row0*/ mload(0x2d00), sub(PRIME, /*column9_row1*/ mload(0x2d20)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[101].
              res := addmod(res,
                            mulmod(val, /*coefficients[101]*/ mload(0x1220), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/x: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column9_row1 - column9_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4960),
                addmod(/*column9_row1*/ mload(0x2d20), sub(PRIME, /*column9_row0*/ mload(0x2d00)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[102].
              res := addmod(res,
                            mulmod(val, /*coefficients[102]*/ mload(0x1240), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/y: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column10_row1 - column10_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4960),
                addmod(/*column10_row1*/ mload(0x2dc0), sub(PRIME, /*column10_row0*/ mload(0x2da0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[103].
              res := addmod(res,
                            mulmod(val, /*coefficients[103]*/ mload(0x1260), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/x: column9_row256 - column9_row255.
              let val := addmod(
                /*column9_row256*/ mload(0x2d60),
                sub(PRIME, /*column9_row255*/ mload(0x2d40)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[104].
              res := addmod(res,
                            mulmod(val, /*coefficients[104]*/ mload(0x1280), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/y: column10_row256 - column10_row255.
              let val := addmod(
                /*column10_row256*/ mload(0x2e00),
                sub(PRIME, /*column10_row255*/ mload(0x2de0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[105].
              res := addmod(res,
                            mulmod(val, /*coefficients[105]*/ mload(0x12a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/x: column9_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column9_row0*/ mload(0x2d00),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[106].
              res := addmod(res,
                            mulmod(val, /*coefficients[106]*/ mload(0x12c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/y: column10_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column10_row0*/ mload(0x2da0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[107].
              res := addmod(res,
                            mulmod(val, /*coefficients[107]*/ mload(0x12e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/last_one_is_zero: column23_row209 * (column14_row0 - (column14_row1 + column14_row1)).
              let val := mulmod(
                /*column23_row209*/ mload(0x42c0),
                addmod(
                  /*column14_row0*/ mload(0x3060),
                  sub(
                    PRIME,
                    addmod(/*column14_row1*/ mload(0x3080), /*column14_row1*/ mload(0x3080), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[108].
              res := addmod(res,
                            mulmod(val, /*coefficients[108]*/ mload(0x1300), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column23_row209 * (column14_row1 - 3138550867693340381917894711603833208051177722232017256448 * column14_row192).
              let val := mulmod(
                /*column23_row209*/ mload(0x42c0),
                addmod(
                  /*column14_row1*/ mload(0x3080),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column14_row192*/ mload(0x30a0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[109].
              res := addmod(res,
                            mulmod(val, /*coefficients[109]*/ mload(0x1320), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit192: column23_row209 - column23_row81 * (column14_row192 - (column14_row193 + column14_row193)).
              let val := addmod(
                /*column23_row209*/ mload(0x42c0),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row81*/ mload(0x4280),
                    addmod(
                      /*column14_row192*/ mload(0x30a0),
                      sub(
                        PRIME,
                        addmod(/*column14_row193*/ mload(0x30c0), /*column14_row193*/ mload(0x30c0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[110].
              res := addmod(res,
                            mulmod(val, /*coefficients[110]*/ mload(0x1340), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column23_row81 * (column14_row193 - 8 * column14_row196).
              let val := mulmod(
                /*column23_row81*/ mload(0x4280),
                addmod(
                  /*column14_row193*/ mload(0x30c0),
                  sub(PRIME, mulmod(8, /*column14_row196*/ mload(0x30e0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[111].
              res := addmod(res,
                            mulmod(val, /*coefficients[111]*/ mload(0x1360), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit196: column23_row81 - (column14_row251 - (column14_row252 + column14_row252)) * (column14_row196 - (column14_row197 + column14_row197)).
              let val := addmod(
                /*column23_row81*/ mload(0x4280),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column14_row251*/ mload(0x3120),
                      sub(
                        PRIME,
                        addmod(/*column14_row252*/ mload(0x3140), /*column14_row252*/ mload(0x3140), PRIME)),
                      PRIME),
                    addmod(
                      /*column14_row196*/ mload(0x30e0),
                      sub(
                        PRIME,
                        addmod(/*column14_row197*/ mload(0x3100), /*column14_row197*/ mload(0x3100), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[112].
              res := addmod(res,
                            mulmod(val, /*coefficients[112]*/ mload(0x1380), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column14_row251 - (column14_row252 + column14_row252)) * (column14_row197 - 18014398509481984 * column14_row251).
              let val := mulmod(
                addmod(
                  /*column14_row251*/ mload(0x3120),
                  sub(
                    PRIME,
                    addmod(/*column14_row252*/ mload(0x3140), /*column14_row252*/ mload(0x3140), PRIME)),
                  PRIME),
                addmod(
                  /*column14_row197*/ mload(0x3100),
                  sub(PRIME, mulmod(18014398509481984, /*column14_row251*/ mload(0x3120), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[113].
              res := addmod(res,
                            mulmod(val, /*coefficients[113]*/ mload(0x13a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/booleanity_test: pedersen__hash3__ec_subset_sum__bit_0 * (pedersen__hash3__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980),
                addmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[114].
              res := addmod(res,
                            mulmod(val, /*coefficients[114]*/ mload(0x13c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_extraction_end: column14_row0.
              let val := /*column14_row0*/ mload(0x3060)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x5560), PRIME)

              // res += val * coefficients[115].
              res := addmod(res,
                            mulmod(val, /*coefficients[115]*/ mload(0x13e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/zeros_tail: column14_row0.
              let val := /*column14_row0*/ mload(0x3060)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x5540), PRIME)

              // res += val * coefficients[116].
              res := addmod(res,
                            mulmod(val, /*coefficients[116]*/ mload(0x1400), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/slope: pedersen__hash3__ec_subset_sum__bit_0 * (column13_row0 - pedersen__points__y) - column18_row0 * (column12_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980),
                  addmod(
                    /*column13_row0*/ mload(0x2fe0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column18_row0*/ mload(0x3240),
                    addmod(
                      /*column12_row0*/ mload(0x2f40),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[117].
              res := addmod(res,
                            mulmod(val, /*coefficients[117]*/ mload(0x1420), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/x: column18_row0 * column18_row0 - pedersen__hash3__ec_subset_sum__bit_0 * (column12_row0 + pedersen__points__x + column12_row1).
              let val := addmod(
                mulmod(/*column18_row0*/ mload(0x3240), /*column18_row0*/ mload(0x3240), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980),
                    addmod(
                      addmod(
                        /*column12_row0*/ mload(0x2f40),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column12_row1*/ mload(0x2f60),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[118].
              res := addmod(res,
                            mulmod(val, /*coefficients[118]*/ mload(0x1440), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/y: pedersen__hash3__ec_subset_sum__bit_0 * (column13_row0 + column13_row1) - column18_row0 * (column12_row0 - column12_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4980),
                  addmod(/*column13_row0*/ mload(0x2fe0), /*column13_row1*/ mload(0x3000), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column18_row0*/ mload(0x3240),
                    addmod(/*column12_row0*/ mload(0x2f40), sub(PRIME, /*column12_row1*/ mload(0x2f60)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[119].
              res := addmod(res,
                            mulmod(val, /*coefficients[119]*/ mload(0x1460), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/x: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column12_row1 - column12_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x49a0),
                addmod(/*column12_row1*/ mload(0x2f60), sub(PRIME, /*column12_row0*/ mload(0x2f40)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[120].
              res := addmod(res,
                            mulmod(val, /*coefficients[120]*/ mload(0x1480), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/y: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column13_row1 - column13_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x49a0),
                addmod(/*column13_row1*/ mload(0x3000), sub(PRIME, /*column13_row0*/ mload(0x2fe0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x5180), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x5420), PRIME)

              // res += val * coefficients[121].
              res := addmod(res,
                            mulmod(val, /*coefficients[121]*/ mload(0x14a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/x: column12_row256 - column12_row255.
              let val := addmod(
                /*column12_row256*/ mload(0x2fa0),
                sub(PRIME, /*column12_row255*/ mload(0x2f80)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[122].
              res := addmod(res,
                            mulmod(val, /*coefficients[122]*/ mload(0x14c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/y: column13_row256 - column13_row255.
              let val := addmod(
                /*column13_row256*/ mload(0x3040),
                sub(PRIME, /*column13_row255*/ mload(0x3020)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= domains[9].
              val := mulmod(val, /*domains[9]*/ mload(0x51c0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x5520), PRIME)

              // res += val * coefficients[123].
              res := addmod(res,
                            mulmod(val, /*coefficients[123]*/ mload(0x14e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/x: column12_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column12_row0*/ mload(0x2f40),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[124].
              res := addmod(res,
                            mulmod(val, /*coefficients[124]*/ mload(0x1500), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/y: column13_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column13_row0*/ mload(0x2fe0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[125].
              res := addmod(res,
                            mulmod(val, /*coefficients[125]*/ mload(0x1520), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column19_row11 - column5_row0.
              let val := addmod(/*column19_row11*/ mload(0x33a0), sub(PRIME, /*column5_row0*/ mload(0x29a0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[126].
              res := addmod(res,
                            mulmod(val, /*coefficients[126]*/ mload(0x1540), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value1: column19_row139 - column8_row0.
              let val := addmod(
                /*column19_row139*/ mload(0x3540),
                sub(PRIME, /*column8_row0*/ mload(0x2be0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[127].
              res := addmod(res,
                            mulmod(val, /*coefficients[127]*/ mload(0x1560), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value2: column19_row267 - column11_row0.
              let val := addmod(
                /*column19_row267*/ mload(0x35c0),
                sub(PRIME, /*column11_row0*/ mload(0x2e20)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[128].
              res := addmod(res,
                            mulmod(val, /*coefficients[128]*/ mload(0x1580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value3: column19_row395 - column14_row0.
              let val := addmod(
                /*column19_row395*/ mload(0x3660),
                sub(PRIME, /*column14_row0*/ mload(0x3060)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[129].
              res := addmod(res,
                            mulmod(val, /*coefficients[129]*/ mload(0x15a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column19_row138 - (column19_row42 + 1).
              let val := addmod(
                /*column19_row138*/ mload(0x3520),
                sub(PRIME, addmod(/*column19_row42*/ mload(0x3460), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= domains[25].
              val := mulmod(val, /*domains[25]*/ mload(0x53c0), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[130].
              res := addmod(res,
                            mulmod(val, /*coefficients[130]*/ mload(0x15c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column19_row10 - initial_pedersen_addr.
              let val := addmod(
                /*column19_row10*/ mload(0x3380),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[131].
              res := addmod(res,
                            mulmod(val, /*coefficients[131]*/ mload(0x15e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column19_row75 - column5_row256.
              let val := addmod(
                /*column19_row75*/ mload(0x34c0),
                sub(PRIME, /*column5_row256*/ mload(0x2aa0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[132].
              res := addmod(res,
                            mulmod(val, /*coefficients[132]*/ mload(0x1600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value1: column19_row203 - column8_row256.
              let val := addmod(
                /*column19_row203*/ mload(0x3580),
                sub(PRIME, /*column8_row256*/ mload(0x2ce0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[133].
              res := addmod(res,
                            mulmod(val, /*coefficients[133]*/ mload(0x1620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value2: column19_row331 - column11_row256.
              let val := addmod(
                /*column19_row331*/ mload(0x3640),
                sub(PRIME, /*column11_row256*/ mload(0x2f20)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[134].
              res := addmod(res,
                            mulmod(val, /*coefficients[134]*/ mload(0x1640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value3: column19_row459 - column14_row256.
              let val := addmod(
                /*column19_row459*/ mload(0x36a0),
                sub(PRIME, /*column14_row256*/ mload(0x3160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[135].
              res := addmod(res,
                            mulmod(val, /*coefficients[135]*/ mload(0x1660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column19_row74 - (column19_row10 + 1).
              let val := addmod(
                /*column19_row74*/ mload(0x34a0),
                sub(PRIME, addmod(/*column19_row10*/ mload(0x3380), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[136].
              res := addmod(res,
                            mulmod(val, /*coefficients[136]*/ mload(0x1680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column19_row43 - column3_row511.
              let val := addmod(
                /*column19_row43*/ mload(0x3480),
                sub(PRIME, /*column3_row511*/ mload(0x2900)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[137].
              res := addmod(res,
                            mulmod(val, /*coefficients[137]*/ mload(0x16a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value1: column19_row171 - column6_row511.
              let val := addmod(
                /*column19_row171*/ mload(0x3560),
                sub(PRIME, /*column6_row511*/ mload(0x2b40)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[138].
              res := addmod(res,
                            mulmod(val, /*coefficients[138]*/ mload(0x16c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value2: column19_row299 - column9_row511.
              let val := addmod(
                /*column19_row299*/ mload(0x3620),
                sub(PRIME, /*column9_row511*/ mload(0x2d80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[139].
              res := addmod(res,
                            mulmod(val, /*coefficients[139]*/ mload(0x16e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value3: column19_row427 - column12_row511.
              let val := addmod(
                /*column19_row427*/ mload(0x3680),
                sub(PRIME, /*column12_row511*/ mload(0x2fc0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x5580), PRIME)

              // res += val * coefficients[140].
              res := addmod(res,
                            mulmod(val, /*coefficients[140]*/ mload(0x1700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column19_row42 - (column19_row74 + 1).
              let val := addmod(
                /*column19_row42*/ mload(0x3460),
                sub(PRIME, addmod(/*column19_row74*/ mload(0x34a0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[141].
              res := addmod(res,
                            mulmod(val, /*coefficients[141]*/ mload(0x1720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column19_row107.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x4aa0),
                sub(PRIME, /*column19_row107*/ mload(0x3500)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[142].
              res := addmod(res,
                            mulmod(val, /*coefficients[142]*/ mload(0x1740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column19_row234 - (column19_row106 + 1).
              let val := addmod(
                /*column19_row234*/ mload(0x35a0),
                sub(PRIME, addmod(/*column19_row106*/ mload(0x34e0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= domains[25].
              val := mulmod(val, /*domains[25]*/ mload(0x53c0), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x55a0), PRIME)

              // res += val * coefficients[143].
              res := addmod(res,
                            mulmod(val, /*coefficients[143]*/ mload(0x1760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column19_row106 - initial_rc_addr.
              let val := addmod(
                /*column19_row106*/ mload(0x34e0),
                sub(PRIME, /*initial_rc_addr*/ mload(0x360)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[144].
              res := addmod(res,
                            mulmod(val, /*coefficients[144]*/ mload(0x1780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/slope: ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa/sig_config.alpha - (column22_row14 + column22_row14) * column23_row8.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4ac0),
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4ac0),
                      PRIME),
                    /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x4ac0),
                    PRIME),
                  /*ecdsa/sig_config.alpha*/ mload(0x380),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column22_row14*/ mload(0x3de0), /*column22_row14*/ mload(0x3de0), PRIME),
                    /*column23_row8*/ mload(0x4120),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[145].
              res := addmod(res,
                            mulmod(val, /*coefficients[145]*/ mload(0x17a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/x: column23_row8 * column23_row8 - (column22_row6 + column22_row6 + column22_row22).
              let val := addmod(
                mulmod(/*column23_row8*/ mload(0x4120), /*column23_row8*/ mload(0x4120), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column22_row6*/ mload(0x3ce0), /*column22_row6*/ mload(0x3ce0), PRIME),
                    /*column22_row22*/ mload(0x3ea0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[146].
              res := addmod(res,
                            mulmod(val, /*coefficients[146]*/ mload(0x17c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/y: column22_row14 + column22_row30 - column23_row8 * (column22_row6 - column22_row22).
              let val := addmod(
                addmod(/*column22_row14*/ mload(0x3de0), /*column22_row30*/ mload(0x3f40), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row8*/ mload(0x4120),
                    addmod(
                      /*column22_row6*/ mload(0x3ce0),
                      sub(PRIME, /*column22_row22*/ mload(0x3ea0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[147].
              res := addmod(res,
                            mulmod(val, /*coefficients[147]*/ mload(0x17e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/booleanity_test: ecdsa__signature0__exponentiate_generator__bit_0 * (ecdsa__signature0__exponentiate_generator__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[148].
              res := addmod(res,
                            mulmod(val, /*coefficients[148]*/ mload(0x1800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/bit_extraction_end: column23_row14.
              let val := /*column23_row14*/ mload(0x4180)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, /*denominator_invs[16]*/ mload(0x5620), PRIME)

              // res += val * coefficients[149].
              res := addmod(res,
                            mulmod(val, /*coefficients[149]*/ mload(0x1820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/zeros_tail: column23_row14.
              let val := /*column23_row14*/ mload(0x4180)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x5600), PRIME)

              // res += val * coefficients[150].
              res := addmod(res,
                            mulmod(val, /*coefficients[150]*/ mload(0x1840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/slope: ecdsa__signature0__exponentiate_generator__bit_0 * (column23_row22 - ecdsa__generator_points__y) - column23_row30 * (column23_row6 - ecdsa__generator_points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0),
                  addmod(
                    /*column23_row22*/ mload(0x41e0),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/y*/ mload(0x60)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row30*/ mload(0x4200),
                    addmod(
                      /*column23_row6*/ mload(0x4100),
                      sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[151].
              res := addmod(res,
                            mulmod(val, /*coefficients[151]*/ mload(0x1860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x: column23_row30 * column23_row30 - ecdsa__signature0__exponentiate_generator__bit_0 * (column23_row6 + ecdsa__generator_points__x + column23_row38).
              let val := addmod(
                mulmod(/*column23_row30*/ mload(0x4200), /*column23_row30*/ mload(0x4200), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0),
                    addmod(
                      addmod(
                        /*column23_row6*/ mload(0x4100),
                        /*periodic_column/ecdsa/generator_points/x*/ mload(0x40),
                        PRIME),
                      /*column23_row38*/ mload(0x4220),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[152].
              res := addmod(res,
                            mulmod(val, /*coefficients[152]*/ mload(0x1880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/y: ecdsa__signature0__exponentiate_generator__bit_0 * (column23_row22 + column23_row54) - column23_row30 * (column23_row6 - column23_row38).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x4ae0),
                  addmod(/*column23_row22*/ mload(0x41e0), /*column23_row54*/ mload(0x4260), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row30*/ mload(0x4200),
                    addmod(
                      /*column23_row6*/ mload(0x4100),
                      sub(PRIME, /*column23_row38*/ mload(0x4220)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[153].
              res := addmod(res,
                            mulmod(val, /*coefficients[153]*/ mload(0x18a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv: column23_row1 * (column23_row6 - ecdsa__generator_points__x) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row1*/ mload(0x40a0),
                  addmod(
                    /*column23_row6*/ mload(0x4100),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[154].
              res := addmod(res,
                            mulmod(val, /*coefficients[154]*/ mload(0x18c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/x: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column23_row38 - column23_row6).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x4b00),
                addmod(
                  /*column23_row38*/ mload(0x4220),
                  sub(PRIME, /*column23_row6*/ mload(0x4100)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[155].
              res := addmod(res,
                            mulmod(val, /*coefficients[155]*/ mload(0x18e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/y: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column23_row54 - column23_row22).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x4b00),
                addmod(
                  /*column23_row54*/ mload(0x4260),
                  sub(PRIME, /*column23_row22*/ mload(0x41e0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x52e0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x55e0), PRIME)

              // res += val * coefficients[156].
              res := addmod(res,
                            mulmod(val, /*coefficients[156]*/ mload(0x1900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/booleanity_test: ecdsa__signature0__exponentiate_key__bit_0 * (ecdsa__signature0__exponentiate_key__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[157].
              res := addmod(res,
                            mulmod(val, /*coefficients[157]*/ mload(0x1920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/bit_extraction_end: column22_row5.
              let val := /*column22_row5*/ mload(0x3cc0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[17].
              val := mulmod(val, /*denominator_invs[17]*/ mload(0x5640), PRIME)

              // res += val * coefficients[158].
              res := addmod(res,
                            mulmod(val, /*coefficients[158]*/ mload(0x1940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/zeros_tail: column22_row5.
              let val := /*column22_row5*/ mload(0x3cc0)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[159].
              res := addmod(res,
                            mulmod(val, /*coefficients[159]*/ mload(0x1960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/slope: ecdsa__signature0__exponentiate_key__bit_0 * (column22_row9 - column22_row14) - column23_row4 * (column22_row1 - column22_row6).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20),
                  addmod(
                    /*column22_row9*/ mload(0x3d40),
                    sub(PRIME, /*column22_row14*/ mload(0x3de0)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row4*/ mload(0x40e0),
                    addmod(/*column22_row1*/ mload(0x3c40), sub(PRIME, /*column22_row6*/ mload(0x3ce0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[160].
              res := addmod(res,
                            mulmod(val, /*coefficients[160]*/ mload(0x1980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x: column23_row4 * column23_row4 - ecdsa__signature0__exponentiate_key__bit_0 * (column22_row1 + column22_row6 + column22_row17).
              let val := addmod(
                mulmod(/*column23_row4*/ mload(0x40e0), /*column23_row4*/ mload(0x40e0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20),
                    addmod(
                      addmod(/*column22_row1*/ mload(0x3c40), /*column22_row6*/ mload(0x3ce0), PRIME),
                      /*column22_row17*/ mload(0x3e40),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[161].
              res := addmod(res,
                            mulmod(val, /*coefficients[161]*/ mload(0x19a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/y: ecdsa__signature0__exponentiate_key__bit_0 * (column22_row9 + column22_row25) - column23_row4 * (column22_row1 - column22_row17).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4b20),
                  addmod(/*column22_row9*/ mload(0x3d40), /*column22_row25*/ mload(0x3f00), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row4*/ mload(0x40e0),
                    addmod(
                      /*column22_row1*/ mload(0x3c40),
                      sub(PRIME, /*column22_row17*/ mload(0x3e40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[162].
              res := addmod(res,
                            mulmod(val, /*coefficients[162]*/ mload(0x19c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x_diff_inv: column23_row12 * (column22_row1 - column22_row6) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row12*/ mload(0x4160),
                  addmod(/*column22_row1*/ mload(0x3c40), sub(PRIME, /*column22_row6*/ mload(0x3ce0)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[163].
              res := addmod(res,
                            mulmod(val, /*coefficients[163]*/ mload(0x19e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/x: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column22_row17 - column22_row1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4b40),
                addmod(
                  /*column22_row17*/ mload(0x3e40),
                  sub(PRIME, /*column22_row1*/ mload(0x3c40)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[164].
              res := addmod(res,
                            mulmod(val, /*coefficients[164]*/ mload(0x1a00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/y: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column22_row25 - column22_row9).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4b40),
                addmod(
                  /*column22_row25*/ mload(0x3f00),
                  sub(PRIME, /*column22_row9*/ mload(0x3d40)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[165].
              res := addmod(res,
                            mulmod(val, /*coefficients[165]*/ mload(0x1a20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/x: column23_row6 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column23_row6*/ mload(0x4100),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[166].
              res := addmod(res,
                            mulmod(val, /*coefficients[166]*/ mload(0x1a40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/y: column23_row22 + ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column23_row22*/ mload(0x41e0),
                /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[167].
              res := addmod(res,
                            mulmod(val, /*coefficients[167]*/ mload(0x1a60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/x: column22_row1 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column22_row1*/ mload(0x3c40),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[168].
              res := addmod(res,
                            mulmod(val, /*coefficients[168]*/ mload(0x1a80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/y: column22_row9 - ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column22_row9*/ mload(0x3d40),
                sub(PRIME, /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[169].
              res := addmod(res,
                            mulmod(val, /*coefficients[169]*/ mload(0x1aa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/slope: column23_row8182 - (column22_row4089 + column23_row8190 * (column23_row8166 - column22_row4081)).
              let val := addmod(
                /*column23_row8182*/ mload(0x44a0),
                sub(
                  PRIME,
                  addmod(
                    /*column22_row4089*/ mload(0x3fc0),
                    mulmod(
                      /*column23_row8190*/ mload(0x44e0),
                      addmod(
                        /*column23_row8166*/ mload(0x4460),
                        sub(PRIME, /*column22_row4081*/ mload(0x3f80)),
                        PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[170].
              res := addmod(res,
                            mulmod(val, /*coefficients[170]*/ mload(0x1ac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x: column23_row8190 * column23_row8190 - (column23_row8166 + column22_row4081 + column22_row4102).
              let val := addmod(
                mulmod(/*column23_row8190*/ mload(0x44e0), /*column23_row8190*/ mload(0x44e0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column23_row8166*/ mload(0x4460), /*column22_row4081*/ mload(0x3f80), PRIME),
                    /*column22_row4102*/ mload(0x4000),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[171].
              res := addmod(res,
                            mulmod(val, /*coefficients[171]*/ mload(0x1ae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/y: column23_row8182 + column22_row4110 - column23_row8190 * (column23_row8166 - column22_row4102).
              let val := addmod(
                addmod(/*column23_row8182*/ mload(0x44a0), /*column22_row4110*/ mload(0x4020), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row8190*/ mload(0x44e0),
                    addmod(
                      /*column23_row8166*/ mload(0x4460),
                      sub(PRIME, /*column22_row4102*/ mload(0x4000)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[172].
              res := addmod(res,
                            mulmod(val, /*coefficients[172]*/ mload(0x1b00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x_diff_inv: column23_row8161 * (column23_row8166 - column22_row4081) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row8161*/ mload(0x4440),
                  addmod(
                    /*column23_row8166*/ mload(0x4460),
                    sub(PRIME, /*column22_row4081*/ mload(0x3f80)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[173].
              res := addmod(res,
                            mulmod(val, /*coefficients[173]*/ mload(0x1b20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/slope: column22_row8185 + ecdsa/sig_config.shift_point.y - column23_row4082 * (column22_row8177 - ecdsa/sig_config.shift_point.x).
              let val := addmod(
                addmod(
                  /*column22_row8185*/ mload(0x4060),
                  /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row4082*/ mload(0x43a0),
                    addmod(
                      /*column22_row8177*/ mload(0x4040),
                      sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[174].
              res := addmod(res,
                            mulmod(val, /*coefficients[174]*/ mload(0x1b40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x: column23_row4082 * column23_row4082 - (column22_row8177 + ecdsa/sig_config.shift_point.x + column22_row5).
              let val := addmod(
                mulmod(/*column23_row4082*/ mload(0x43a0), /*column23_row4082*/ mload(0x43a0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*column22_row8177*/ mload(0x4040),
                      /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0),
                      PRIME),
                    /*column22_row5*/ mload(0x3cc0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[175].
              res := addmod(res,
                            mulmod(val, /*coefficients[175]*/ mload(0x1b60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x_diff_inv: column23_row8178 * (column22_row8177 - ecdsa/sig_config.shift_point.x) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row8178*/ mload(0x4480),
                  addmod(
                    /*column22_row8177*/ mload(0x4040),
                    sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[176].
              res := addmod(res,
                            mulmod(val, /*coefficients[176]*/ mload(0x1b80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/z_nonzero: column23_row14 * column23_row4090 - 1.
              let val := addmod(
                mulmod(/*column23_row14*/ mload(0x4180), /*column23_row4090*/ mload(0x4400), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[177].
              res := addmod(res,
                            mulmod(val, /*coefficients[177]*/ mload(0x1ba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/r_and_w_nonzero: column22_row5 * column23_row4088 - 1.
              let val := addmod(
                mulmod(/*column22_row5*/ mload(0x3cc0), /*column23_row4088*/ mload(0x43e0), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[178].
              res := addmod(res,
                            mulmod(val, /*coefficients[178]*/ mload(0x1bc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/x_squared: column23_row8186 - column22_row6 * column22_row6.
              let val := addmod(
                /*column23_row8186*/ mload(0x44c0),
                sub(
                  PRIME,
                  mulmod(/*column22_row6*/ mload(0x3ce0), /*column22_row6*/ mload(0x3ce0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[179].
              res := addmod(res,
                            mulmod(val, /*coefficients[179]*/ mload(0x1be0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/on_curve: column22_row14 * column22_row14 - (column22_row6 * column23_row8186 + ecdsa/sig_config.alpha * column22_row6 + ecdsa/sig_config.beta).
              let val := addmod(
                mulmod(/*column22_row14*/ mload(0x3de0), /*column22_row14*/ mload(0x3de0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(/*column22_row6*/ mload(0x3ce0), /*column23_row8186*/ mload(0x44c0), PRIME),
                      mulmod(/*ecdsa/sig_config.alpha*/ mload(0x380), /*column22_row6*/ mload(0x3ce0), PRIME),
                      PRIME),
                    /*ecdsa/sig_config.beta*/ mload(0x3e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[180].
              res := addmod(res,
                            mulmod(val, /*coefficients[180]*/ mload(0x1c00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/init_addr: column19_row26 - initial_ecdsa_addr.
              let val := addmod(
                /*column19_row26*/ mload(0x3420),
                sub(PRIME, /*initial_ecdsa_addr*/ mload(0x400)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[181].
              res := addmod(res,
                            mulmod(val, /*coefficients[181]*/ mload(0x1c20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_addr: column19_row4122 - (column19_row26 + 1).
              let val := addmod(
                /*column19_row4122*/ mload(0x3940),
                sub(PRIME, addmod(/*column19_row26*/ mload(0x3420), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[182].
              res := addmod(res,
                            mulmod(val, /*coefficients[182]*/ mload(0x1c40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_addr: column19_row8218 - (column19_row4122 + 1).
              let val := addmod(
                /*column19_row8218*/ mload(0x39c0),
                sub(PRIME, addmod(/*column19_row4122*/ mload(0x3940), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              // val *= domains[26].
              val := mulmod(val, /*domains[26]*/ mload(0x53e0), PRIME)
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[183].
              res := addmod(res,
                            mulmod(val, /*coefficients[183]*/ mload(0x1c60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_value0: column19_row4123 - column23_row14.
              let val := addmod(
                /*column19_row4123*/ mload(0x3960),
                sub(PRIME, /*column23_row14*/ mload(0x4180)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[184].
              res := addmod(res,
                            mulmod(val, /*coefficients[184]*/ mload(0x1c80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_value0: column19_row27 - column22_row6.
              let val := addmod(
                /*column19_row27*/ mload(0x3440),
                sub(PRIME, /*column22_row6*/ mload(0x3ce0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, /*denominator_invs[18]*/ mload(0x5660), PRIME)

              // res += val * coefficients[185].
              res := addmod(res,
                            mulmod(val, /*coefficients[185]*/ mload(0x1ca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/init_var_pool_addr: column19_row538 - initial_bitwise_addr.
              let val := addmod(
                /*column19_row538*/ mload(0x36c0),
                sub(PRIME, /*initial_bitwise_addr*/ mload(0x420)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[186].
              res := addmod(res,
                            mulmod(val, /*coefficients[186]*/ mload(0x1cc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/step_var_pool_addr: column19_row1562 - (column19_row538 + 1).
              let val := addmod(
                /*column19_row1562*/ mload(0x37c0),
                sub(PRIME, addmod(/*column19_row538*/ mload(0x36c0), 1, PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(3 * trace_length / 4).
              // val *= domains[15].
              val := mulmod(val, /*domains[15]*/ mload(0x5280), PRIME)
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, /*denominator_invs[20]*/ mload(0x56a0), PRIME)

              // res += val * coefficients[187].
              res := addmod(res,
                            mulmod(val, /*coefficients[187]*/ mload(0x1ce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/x_or_y_addr: column19_row2074 - (column19_row3610 + 1).
              let val := addmod(
                /*column19_row2074*/ mload(0x37e0),
                sub(PRIME, addmod(/*column19_row3610*/ mload(0x3900), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[188].
              res := addmod(res,
                            mulmod(val, /*coefficients[188]*/ mload(0x1d00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/next_var_pool_addr: column19_row4634 - (column19_row2074 + 1).
              let val := addmod(
                /*column19_row4634*/ mload(0x3980),
                sub(PRIME, addmod(/*column19_row2074*/ mload(0x37e0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4096 * (trace_length / 4096 - 1)).
              // val *= domains[27].
              val := mulmod(val, /*domains[27]*/ mload(0x5400), PRIME)
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[189].
              res := addmod(res,
                            mulmod(val, /*coefficients[189]*/ mload(0x1d20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/partition: bitwise__sum_var_0_0 + bitwise__sum_var_8_0 - column19_row539.
              let val := addmod(
                addmod(
                  /*intermediate_value/bitwise/sum_var_0_0*/ mload(0x4b60),
                  /*intermediate_value/bitwise/sum_var_8_0*/ mload(0x4b80),
                  PRIME),
                sub(PRIME, /*column19_row539*/ mload(0x36e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, /*denominator_invs[20]*/ mload(0x56a0), PRIME)

              // res += val * coefficients[190].
              res := addmod(res,
                            mulmod(val, /*coefficients[190]*/ mload(0x1d40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/or_is_and_plus_xor: column19_row2075 - (column19_row2587 + column19_row3611).
              let val := addmod(
                /*column19_row2075*/ mload(0x3800),
                sub(
                  PRIME,
                  addmod(/*column19_row2587*/ mload(0x3860), /*column19_row3611*/ mload(0x3920), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[191].
              res := addmod(res,
                            mulmod(val, /*coefficients[191]*/ mload(0x1d60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/addition_is_xor_with_and: column1_row0 + column1_row1024 - (column1_row3072 + column1_row2048 + column1_row2048).
              let val := addmod(
                addmod(/*column1_row0*/ mload(0x2440), /*column1_row1024*/ mload(0x2680), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column1_row3072*/ mload(0x2780), /*column1_row2048*/ mload(0x26c0), PRIME),
                    /*column1_row2048*/ mload(0x26c0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: (point^(trace_length / 4096) - trace_generator^(trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 8)) * (point^(trace_length / 4096) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(15 * trace_length / 64)) * domain14.
              // val *= denominator_invs[21].
              val := mulmod(val, /*denominator_invs[21]*/ mload(0x56c0), PRIME)

              // res += val * coefficients[192].
              res := addmod(res,
                            mulmod(val, /*coefficients[192]*/ mload(0x1d80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking192: (column1_row2816 + column1_row3840) * 16 - column1_row32.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2816*/ mload(0x2700), /*column1_row3840*/ mload(0x27c0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row32*/ mload(0x2480)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[193].
              res := addmod(res,
                            mulmod(val, /*coefficients[193]*/ mload(0x1da0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking193: (column1_row2880 + column1_row3904) * 16 - column1_row2080.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2880*/ mload(0x2720), /*column1_row3904*/ mload(0x27e0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row2080*/ mload(0x26e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[194].
              res := addmod(res,
                            mulmod(val, /*coefficients[194]*/ mload(0x1dc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking194: (column1_row2944 + column1_row3968) * 16 - column1_row1056.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2944*/ mload(0x2740), /*column1_row3968*/ mload(0x2800), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row1056*/ mload(0x26a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[195].
              res := addmod(res,
                            mulmod(val, /*coefficients[195]*/ mload(0x1de0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking195: (column1_row3008 + column1_row4032) * 256 - column1_row3104.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row3008*/ mload(0x2760), /*column1_row4032*/ mload(0x2820), PRIME),
                  256,
                  PRIME),
                sub(PRIME, /*column1_row3104*/ mload(0x27a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[196].
              res := addmod(res,
                            mulmod(val, /*coefficients[196]*/ mload(0x1e00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/init_addr: column19_row1050 - initial_ec_op_addr.
              let val := addmod(
                /*column19_row1050*/ mload(0x3740),
                sub(PRIME, /*initial_ec_op_addr*/ mload(0x440)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x54a0), PRIME)

              // res += val * coefficients[197].
              res := addmod(res,
                            mulmod(val, /*coefficients[197]*/ mload(0x1e20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/p_x_addr: column19_row5146 - (column19_row1050 + 7).
              let val := addmod(
                /*column19_row5146*/ mload(0x39a0),
                sub(PRIME, addmod(/*column19_row1050*/ mload(0x3740), 7, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4096 * (trace_length / 4096 - 1)).
              // val *= domains[27].
              val := mulmod(val, /*domains[27]*/ mload(0x5400), PRIME)
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[198].
              res := addmod(res,
                            mulmod(val, /*coefficients[198]*/ mload(0x1e40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/p_y_addr: column19_row3098 - (column19_row1050 + 1).
              let val := addmod(
                /*column19_row3098*/ mload(0x3880),
                sub(PRIME, addmod(/*column19_row1050*/ mload(0x3740), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[199].
              res := addmod(res,
                            mulmod(val, /*coefficients[199]*/ mload(0x1e60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/q_x_addr: column19_row282 - (column19_row3098 + 1).
              let val := addmod(
                /*column19_row282*/ mload(0x35e0),
                sub(PRIME, addmod(/*column19_row3098*/ mload(0x3880), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[200].
              res := addmod(res,
                            mulmod(val, /*coefficients[200]*/ mload(0x1e80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/q_y_addr: column19_row2330 - (column19_row282 + 1).
              let val := addmod(
                /*column19_row2330*/ mload(0x3820),
                sub(PRIME, addmod(/*column19_row282*/ mload(0x35e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[201].
              res := addmod(res,
                            mulmod(val, /*coefficients[201]*/ mload(0x1ea0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/m_addr: column19_row1306 - (column19_row2330 + 1).
              let val := addmod(
                /*column19_row1306*/ mload(0x3780),
                sub(PRIME, addmod(/*column19_row2330*/ mload(0x3820), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[202].
              res := addmod(res,
                            mulmod(val, /*coefficients[202]*/ mload(0x1ec0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/r_x_addr: column19_row3354 - (column19_row1306 + 1).
              let val := addmod(
                /*column19_row3354*/ mload(0x38c0),
                sub(PRIME, addmod(/*column19_row1306*/ mload(0x3780), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[203].
              res := addmod(res,
                            mulmod(val, /*coefficients[203]*/ mload(0x1ee0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/r_y_addr: column19_row794 - (column19_row3354 + 1).
              let val := addmod(
                /*column19_row794*/ mload(0x3700),
                sub(PRIME, addmod(/*column19_row3354*/ mload(0x38c0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[204].
              res := addmod(res,
                            mulmod(val, /*coefficients[204]*/ mload(0x1f00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/slope: ec_op__doubling_q__x_squared_0 + ec_op__doubling_q__x_squared_0 + ec_op__doubling_q__x_squared_0 + ec_op/curve_config.alpha - (column22_row3 + column22_row3) * column22_row11.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4ba0),
                      /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4ba0),
                      PRIME),
                    /*intermediate_value/ec_op/doubling_q/x_squared_0*/ mload(0x4ba0),
                    PRIME),
                  /*ec_op/curve_config.alpha*/ mload(0x460),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column22_row3*/ mload(0x3c80), /*column22_row3*/ mload(0x3c80), PRIME),
                    /*column22_row11*/ mload(0x3d80),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[205].
              res := addmod(res,
                            mulmod(val, /*coefficients[205]*/ mload(0x1f20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/x: column22_row11 * column22_row11 - (column22_row13 + column22_row13 + column22_row29).
              let val := addmod(
                mulmod(/*column22_row11*/ mload(0x3d80), /*column22_row11*/ mload(0x3d80), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column22_row13*/ mload(0x3dc0), /*column22_row13*/ mload(0x3dc0), PRIME),
                    /*column22_row29*/ mload(0x3f20),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[206].
              res := addmod(res,
                            mulmod(val, /*coefficients[206]*/ mload(0x1f40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/doubling_q/y: column22_row3 + column22_row19 - column22_row11 * (column22_row13 - column22_row29).
              let val := addmod(
                addmod(/*column22_row3*/ mload(0x3c80), /*column22_row19*/ mload(0x3e60), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row11*/ mload(0x3d80),
                    addmod(
                      /*column22_row13*/ mload(0x3dc0),
                      sub(PRIME, /*column22_row29*/ mload(0x3f20)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[207].
              res := addmod(res,
                            mulmod(val, /*coefficients[207]*/ mload(0x1f60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_q_x: column19_row283 - column22_row13.
              let val := addmod(
                /*column19_row283*/ mload(0x3600),
                sub(PRIME, /*column22_row13*/ mload(0x3dc0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[208].
              res := addmod(res,
                            mulmod(val, /*coefficients[208]*/ mload(0x1f80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_q_y: column19_row2331 - column22_row3.
              let val := addmod(
                /*column19_row2331*/ mload(0x3840),
                sub(PRIME, /*column22_row3*/ mload(0x3c80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[209].
              res := addmod(res,
                            mulmod(val, /*coefficients[209]*/ mload(0x1fa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/last_one_is_zero: column23_row4092 * (column23_row0 - (column23_row16 + column23_row16)).
              let val := mulmod(
                /*column23_row4092*/ mload(0x4420),
                addmod(
                  /*column23_row0*/ mload(0x4080),
                  sub(
                    PRIME,
                    addmod(/*column23_row16*/ mload(0x41a0), /*column23_row16*/ mload(0x41a0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[210].
              res := addmod(res,
                            mulmod(val, /*coefficients[210]*/ mload(0x1fc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column23_row4092 * (column23_row16 - 3138550867693340381917894711603833208051177722232017256448 * column23_row3072).
              let val := mulmod(
                /*column23_row4092*/ mload(0x4420),
                addmod(
                  /*column23_row16*/ mload(0x41a0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column23_row3072*/ mload(0x42e0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[211].
              res := addmod(res,
                            mulmod(val, /*coefficients[211]*/ mload(0x1fe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/cumulative_bit192: column23_row4092 - column23_row4084 * (column23_row3072 - (column23_row3088 + column23_row3088)).
              let val := addmod(
                /*column23_row4092*/ mload(0x4420),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row4084*/ mload(0x43c0),
                    addmod(
                      /*column23_row3072*/ mload(0x42e0),
                      sub(
                        PRIME,
                        addmod(/*column23_row3088*/ mload(0x4300), /*column23_row3088*/ mload(0x4300), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[212].
              res := addmod(res,
                            mulmod(val, /*coefficients[212]*/ mload(0x2000), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column23_row4084 * (column23_row3088 - 8 * column23_row3136).
              let val := mulmod(
                /*column23_row4084*/ mload(0x43c0),
                addmod(
                  /*column23_row3088*/ mload(0x4300),
                  sub(PRIME, mulmod(8, /*column23_row3136*/ mload(0x4320), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[213].
              res := addmod(res,
                            mulmod(val, /*coefficients[213]*/ mload(0x2020), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/cumulative_bit196: column23_row4084 - (column23_row4016 - (column23_row4032 + column23_row4032)) * (column23_row3136 - (column23_row3152 + column23_row3152)).
              let val := addmod(
                /*column23_row4084*/ mload(0x43c0),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column23_row4016*/ mload(0x4360),
                      sub(
                        PRIME,
                        addmod(/*column23_row4032*/ mload(0x4380), /*column23_row4032*/ mload(0x4380), PRIME)),
                      PRIME),
                    addmod(
                      /*column23_row3136*/ mload(0x4320),
                      sub(
                        PRIME,
                        addmod(/*column23_row3152*/ mload(0x4340), /*column23_row3152*/ mload(0x4340), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[214].
              res := addmod(res,
                            mulmod(val, /*coefficients[214]*/ mload(0x2040), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column23_row4016 - (column23_row4032 + column23_row4032)) * (column23_row3152 - 18014398509481984 * column23_row4016).
              let val := mulmod(
                addmod(
                  /*column23_row4016*/ mload(0x4360),
                  sub(
                    PRIME,
                    addmod(/*column23_row4032*/ mload(0x4380), /*column23_row4032*/ mload(0x4380), PRIME)),
                  PRIME),
                addmod(
                  /*column23_row3152*/ mload(0x4340),
                  sub(PRIME, mulmod(18014398509481984, /*column23_row4016*/ mload(0x4360), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[215].
              res := addmod(res,
                            mulmod(val, /*coefficients[215]*/ mload(0x2060), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/booleanity_test: ec_op__ec_subset_sum__bit_0 * (ec_op__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0),
                addmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[216].
              res := addmod(res,
                            mulmod(val, /*coefficients[216]*/ mload(0x2080), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/bit_extraction_end: column23_row0.
              let val := /*column23_row0*/ mload(0x4080)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[22].
              val := mulmod(val, /*denominator_invs[22]*/ mload(0x56e0), PRIME)

              // res += val * coefficients[217].
              res := addmod(res,
                            mulmod(val, /*coefficients[217]*/ mload(0x20a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/zeros_tail: column23_row0.
              let val := /*column23_row0*/ mload(0x4080)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x55c0), PRIME)

              // res += val * coefficients[218].
              res := addmod(res,
                            mulmod(val, /*coefficients[218]*/ mload(0x20c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/slope: ec_op__ec_subset_sum__bit_0 * (column22_row15 - column22_row3) - column23_row2 * (column22_row7 - column22_row13).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0),
                  addmod(
                    /*column22_row15*/ mload(0x3e00),
                    sub(PRIME, /*column22_row3*/ mload(0x3c80)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row2*/ mload(0x40c0),
                    addmod(
                      /*column22_row7*/ mload(0x3d00),
                      sub(PRIME, /*column22_row13*/ mload(0x3dc0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[219].
              res := addmod(res,
                            mulmod(val, /*coefficients[219]*/ mload(0x20e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/x: column23_row2 * column23_row2 - ec_op__ec_subset_sum__bit_0 * (column22_row7 + column22_row13 + column22_row23).
              let val := addmod(
                mulmod(/*column23_row2*/ mload(0x40c0), /*column23_row2*/ mload(0x40c0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0),
                    addmod(
                      addmod(/*column22_row7*/ mload(0x3d00), /*column22_row13*/ mload(0x3dc0), PRIME),
                      /*column22_row23*/ mload(0x3ec0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[220].
              res := addmod(res,
                            mulmod(val, /*coefficients[220]*/ mload(0x2100), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/y: ec_op__ec_subset_sum__bit_0 * (column22_row15 + column22_row31) - column23_row2 * (column22_row7 - column22_row23).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ec_op/ec_subset_sum/bit_0*/ mload(0x4bc0),
                  addmod(/*column22_row15*/ mload(0x3e00), /*column22_row31*/ mload(0x3f60), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row2*/ mload(0x40c0),
                    addmod(
                      /*column22_row7*/ mload(0x3d00),
                      sub(PRIME, /*column22_row23*/ mload(0x3ec0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[221].
              res := addmod(res,
                            mulmod(val, /*coefficients[221]*/ mload(0x2120), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/add_points/x_diff_inv: column23_row10 * (column22_row7 - column22_row13) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row10*/ mload(0x4140),
                  addmod(
                    /*column22_row7*/ mload(0x3d00),
                    sub(PRIME, /*column22_row13*/ mload(0x3dc0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[222].
              res := addmod(res,
                            mulmod(val, /*coefficients[222]*/ mload(0x2140), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/copy_point/x: ec_op__ec_subset_sum__bit_neg_0 * (column22_row23 - column22_row7).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_neg_0*/ mload(0x4be0),
                addmod(
                  /*column22_row23*/ mload(0x3ec0),
                  sub(PRIME, /*column22_row7*/ mload(0x3d00)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[223].
              res := addmod(res,
                            mulmod(val, /*coefficients[223]*/ mload(0x2160), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/ec_subset_sum/copy_point/y: ec_op__ec_subset_sum__bit_neg_0 * (column22_row31 - column22_row15).
              let val := mulmod(
                /*intermediate_value/ec_op/ec_subset_sum/bit_neg_0*/ mload(0x4be0),
                addmod(
                  /*column22_row31*/ mload(0x3f60),
                  sub(PRIME, /*column22_row15*/ mload(0x3e00)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x5220), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x5460), PRIME)

              // res += val * coefficients[224].
              res := addmod(res,
                            mulmod(val, /*coefficients[224]*/ mload(0x2180), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_m: column23_row0 - column19_row1307.
              let val := addmod(
                /*column23_row0*/ mload(0x4080),
                sub(PRIME, /*column19_row1307*/ mload(0x37a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[225].
              res := addmod(res,
                            mulmod(val, /*coefficients[225]*/ mload(0x21a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_p_x: column19_row1051 - column22_row7.
              let val := addmod(
                /*column19_row1051*/ mload(0x3760),
                sub(PRIME, /*column22_row7*/ mload(0x3d00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[226].
              res := addmod(res,
                            mulmod(val, /*coefficients[226]*/ mload(0x21c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/get_p_y: column19_row3099 - column22_row15.
              let val := addmod(
                /*column19_row3099*/ mload(0x38a0),
                sub(PRIME, /*column22_row15*/ mload(0x3e00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[227].
              res := addmod(res,
                            mulmod(val, /*coefficients[227]*/ mload(0x21e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/set_r_x: column19_row3355 - column22_row4087.
              let val := addmod(
                /*column19_row3355*/ mload(0x38e0),
                sub(PRIME, /*column22_row4087*/ mload(0x3fa0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[228].
              res := addmod(res,
                            mulmod(val, /*coefficients[228]*/ mload(0x2200), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ec_op/set_r_y: column19_row795 - column22_row4095.
              let val := addmod(
                /*column19_row795*/ mload(0x3720),
                sub(PRIME, /*column22_row4095*/ mload(0x3fe0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, /*denominator_invs[19]*/ mload(0x5680), PRIME)

              // res += val * coefficients[229].
              res := addmod(res,
                            mulmod(val, /*coefficients[229]*/ mload(0x2220), PRIME),
                            PRIME)
              }

            mstore(0, res)
            return(0, 0x20)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "CpuVerifier.sol";
import "FriStatementVerifier.sol";
import "MerkleStatementVerifier.sol";

contract CpuFrilessVerifier is CpuVerifier, MerkleStatementVerifier, FriStatementVerifier {
    constructor(
        address[] memory auxPolynomials,
        address oodsContract,
        address memoryPageFactRegistry_,
        address merkleStatementContractAddress,
        address friStatementContractAddress,
        uint256 numSecurityBits_,
        uint256 minProofOfWorkBits_
    )
        public
        MerkleStatementVerifier(merkleStatementContractAddress)
        FriStatementVerifier(friStatementContractAddress)
        CpuVerifier(
            auxPolynomials,
            oodsContract,
            memoryPageFactRegistry_,
            numSecurityBits_,
            minProofOfWorkBits_
        )
    {}

    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view override(MerkleStatementVerifier, MerkleVerifier) returns (bytes32) {
        return MerkleStatementVerifier.verifyMerkle(channelPtr, queuePtr, root, n);
    }

    function friVerifyLayers(uint256[] memory ctx)
        internal
        view
        override(FriStatementVerifier, Fri)
    {
        FriStatementVerifier.friVerifyLayers(ctx);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "CpuPublicInputOffsetsBase.sol";

contract CpuPublicInputOffsets is CpuPublicInputOffsetsBase {
    // The following constants are offsets of data expected in the public input.
    uint256 internal constant OFFSET_ECDSA_BEGIN_ADDR = 14;
    uint256 internal constant OFFSET_ECDSA_STOP_PTR = 15;
    uint256 internal constant OFFSET_BITWISE_BEGIN_ADDR = 16;
    uint256 internal constant OFFSET_BITWISE_STOP_ADDR = 17;
    uint256 internal constant OFFSET_EC_OP_BEGIN_ADDR = 18;
    uint256 internal constant OFFSET_EC_OP_STOP_ADDR = 19;
    uint256 internal constant OFFSET_PUBLIC_MEMORY_PADDING_ADDR = 20;
    uint256 internal constant OFFSET_PUBLIC_MEMORY_PADDING_VALUE = 21;
    uint256 internal constant OFFSET_N_PUBLIC_MEMORY_PAGES = 22;
    uint256 internal constant OFFSET_PUBLIC_MEMORY = 23;

    // The format of the public input, starting at OFFSET_PUBLIC_MEMORY is as follows:
    //   * For each page:
    //     * First address in the page (this field is not included for the first page).
    //     * Page size.
    //     * Page hash.
    //   # All data above this line, appears in the initial seed of the proof.
    //   * For each page:
    //     * Cumulative product.

    function getOffsetPageSize(uint256 pageId) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + PAGE_INFO_SIZE * pageId - 1 + PAGE_INFO_SIZE_OFFSET;
    }

    function getOffsetPageHash(uint256 pageId) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + PAGE_INFO_SIZE * pageId - 1 + PAGE_INFO_HASH_OFFSET;
    }

    function getOffsetPageAddr(uint256 pageId) internal pure returns (uint256) {
        require(pageId >= 1, "Address of page 0 is not part of the public input.");
        return OFFSET_PUBLIC_MEMORY + PAGE_INFO_SIZE * pageId - 1 + PAGE_INFO_ADDRESS_OFFSET;
    }

    function getOffsetPageProd(uint256 pageId, uint256 nPages) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + PAGE_INFO_SIZE * nPages - 1 + pageId;
    }

    function getPublicInputLength(uint256 nPages) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + (PAGE_INFO_SIZE + 1) * nPages - 1;
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "PageInfo.sol";

contract CpuPublicInputOffsetsBase is PageInfo {
    // The following constants are offsets of data expected in the public input.
    uint256 internal constant OFFSET_LOG_N_STEPS = 0;
    uint256 internal constant OFFSET_RC_MIN = 1;
    uint256 internal constant OFFSET_RC_MAX = 2;
    uint256 internal constant OFFSET_LAYOUT_CODE = 3;
    uint256 internal constant OFFSET_PROGRAM_BEGIN_ADDR = 4;
    uint256 internal constant OFFSET_PROGRAM_STOP_PTR = 5;
    uint256 internal constant OFFSET_EXECUTION_BEGIN_ADDR = 6;
    uint256 internal constant OFFSET_EXECUTION_STOP_PTR = 7;
    uint256 internal constant OFFSET_OUTPUT_BEGIN_ADDR = 8;
    uint256 internal constant OFFSET_OUTPUT_STOP_PTR = 9;
    uint256 internal constant OFFSET_PEDERSEN_BEGIN_ADDR = 10;
    uint256 internal constant OFFSET_PEDERSEN_STOP_PTR = 11;
    uint256 internal constant OFFSET_RANGE_CHECK_BEGIN_ADDR = 12;
    uint256 internal constant OFFSET_RANGE_CHECK_STOP_PTR = 13;

    // The program segment starts from 1, so that memory address 0 is kept for the null pointer.
    uint256 internal constant INITIAL_PC = 1;
    // The first Cairo instructions are:
    //   ap += n_args; call main; jmp rel 0.
    // As the first two instructions occupy 2 cells each, the "jmp rel 0" instruction is at
    // offset 4 relative to INITIAL_PC.
    uint256 internal constant FINAL_PC = INITIAL_PC + 4;
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "CairoVerifierContract.sol";
import "MemoryPageFactRegistry.sol";
import "CpuConstraintPoly.sol";
import "LayoutSpecific.sol";
import "StarkVerifier.sol";

/*
  Verifies a Cairo statement: there exists a memory assignment and a valid corresponding program
  trace satisfying the public memory requirements, for which if a program starts at pc=INITIAL_PC,
  it runs successfully and ends with pc=FINAL_PC.

  This contract verifies that:
  * Initial pc is INITIAL_PC and final pc is FINAL_PC.
  * The memory assignment satisfies the given public memory requirements.
  * The 16-bit range-checks are properly configured (0 <= rc_min <= rc_max < 2^16).
  * The segments for the builtins do not exceed their maximum length (thus
    when these builtins are properly used in the program, they will function correctly).
  * The layout is valid.

  This contract DOES NOT (those should be verified outside of this contract):
  * verify that the requested program is loaded, starting from INITIAL_PC.
  * verify that the arguments and return values for main() are properly set (e.g., the segment
    pointers).
  * check anything on the program output.
  * verify that [initial_fp - 2] = initial_fp, which is required to guarantee the "safe call"
    feature (that is, all "call" instructions will return, even if the called function is
    malicious). It guarantees that it's not possible to create a cycle in the call stack.
*/
contract CpuVerifier is StarkVerifier, MemoryPageFactRegistryConstants, LayoutSpecific {
    CpuConstraintPoly constraintPoly;
    IFactRegistry memoryPageFactRegistry;

    constructor(
        address[] memory auxPolynomials,
        address oodsContract,
        address memoryPageFactRegistry_,
        uint256 numSecurityBits_,
        uint256 minProofOfWorkBits_
    ) public StarkVerifier(numSecurityBits_, minProofOfWorkBits_, oodsContract) {
        constraintPoly = CpuConstraintPoly(auxPolynomials[0]);
        initPeriodicColumns(auxPolynomials);
        memoryPageFactRegistry = IFactRegistry(memoryPageFactRegistry_);
    }

    function verifyProofExternal(
        uint256[] calldata proofParams,
        uint256[] calldata proof,
        uint256[] calldata publicInput
    ) external override {
        verifyProof(proofParams, proof, publicInput);
    }

    function getNColumnsInTrace() internal pure override returns (uint256) {
        return N_COLUMNS_IN_MASK;
    }

    function getNColumnsInTrace0() internal pure override returns (uint256) {
        return N_COLUMNS_IN_TRACE0;
    }

    function getNColumnsInTrace1() internal pure override returns (uint256) {
        return N_COLUMNS_IN_TRACE1;
    }

    function getNColumnsInComposition() internal pure override returns (uint256) {
        return CONSTRAINTS_DEGREE_BOUND;
    }

    function getMmInteractionElements() internal pure override returns (uint256) {
        return MM_INTERACTION_ELEMENTS;
    }

    function getMmCoefficients() internal pure override returns (uint256) {
        return MM_COEFFICIENTS;
    }

    function getMmOodsValues() internal pure override returns (uint256) {
        return MM_OODS_VALUES;
    }

    function getMmOodsCoefficients() internal pure override returns (uint256) {
        return MM_OODS_COEFFICIENTS;
    }

    function getNInteractionElements() internal pure override returns (uint256) {
        return N_INTERACTION_ELEMENTS;
    }

    function getNCoefficients() internal pure override returns (uint256) {
        return N_COEFFICIENTS;
    }

    function getNOodsValues() internal pure override returns (uint256) {
        return N_OODS_VALUES;
    }

    function getNOodsCoefficients() internal pure override returns (uint256) {
        return N_OODS_COEFFICIENTS;
    }

    function airSpecificInit(uint256[] memory publicInput)
        internal
        view
        override
        returns (uint256[] memory ctx, uint256 logTraceLength)
    {
        require(publicInput.length >= OFFSET_PUBLIC_MEMORY, "publicInput is too short.");
        ctx = new uint256[](MM_CONTEXT_SIZE);

        // Context for generated code.
        ctx[MM_OFFSET_SIZE] = 2**16;
        ctx[MM_HALF_OFFSET_SIZE] = 2**15;

        // Number of steps.
        uint256 logNSteps = publicInput[OFFSET_LOG_N_STEPS];
        require(logNSteps < 50, "Number of steps is too large.");
        ctx[MM_LOG_N_STEPS] = logNSteps;
        logTraceLength = logNSteps + LOG_CPU_COMPONENT_HEIGHT;

        // Range check limits.
        ctx[MM_RC_MIN] = publicInput[OFFSET_RC_MIN];
        ctx[MM_RC_MAX] = publicInput[OFFSET_RC_MAX];
        require(ctx[MM_RC_MIN] <= ctx[MM_RC_MAX], "rc_min must be <= rc_max");
        require(ctx[MM_RC_MAX] < ctx[MM_OFFSET_SIZE], "rc_max out of range");

        // Layout.
        require(publicInput[OFFSET_LAYOUT_CODE] == LAYOUT_CODE, "Layout code mismatch.");

        // Initial and final pc ("program" memory segment).
        ctx[MM_INITIAL_PC] = publicInput[OFFSET_PROGRAM_BEGIN_ADDR];
        ctx[MM_FINAL_PC] = publicInput[OFFSET_PROGRAM_STOP_PTR];
        // Invalid final pc may indicate that the program end was moved, or the program didn't
        // complete.
        require(ctx[MM_INITIAL_PC] == INITIAL_PC, "Invalid initial pc");
        require(ctx[MM_FINAL_PC] == FINAL_PC, "Invalid final pc");

        // Initial and final ap ("execution" memory segment).
        ctx[MM_INITIAL_AP] = publicInput[OFFSET_EXECUTION_BEGIN_ADDR];
        ctx[MM_FINAL_AP] = publicInput[OFFSET_EXECUTION_STOP_PTR];

        // Public memory.
        require(
            publicInput[OFFSET_N_PUBLIC_MEMORY_PAGES] >= 1 &&
                publicInput[OFFSET_N_PUBLIC_MEMORY_PAGES] < 100000,
            "Invalid number of memory pages."
        );
        ctx[MM_N_PUBLIC_MEM_PAGES] = publicInput[OFFSET_N_PUBLIC_MEMORY_PAGES];

        {
            // Compute the total number of public memory entries.
            uint256 n_public_memory_entries = 0;
            for (uint256 page = 0; page < ctx[MM_N_PUBLIC_MEM_PAGES]; page++) {
                uint256 n_page_entries = publicInput[getOffsetPageSize(page)];
                require(n_page_entries < 2**30, "Too many public memory entries in one page.");
                n_public_memory_entries += n_page_entries;
            }
            ctx[MM_N_PUBLIC_MEM_ENTRIES] = n_public_memory_entries;
        }

        uint256 expectedPublicInputLength = getPublicInputLength(ctx[MM_N_PUBLIC_MEM_PAGES]);
        require(expectedPublicInputLength == publicInput.length, "Public input length mismatch.");

        uint256 lmmPublicInputPtr = MM_PUBLIC_INPUT_PTR;
        assembly {
            // Set public input pointer to point at the first word of the public input
            // (skipping length word).
            mstore(add(ctx, mul(add(lmmPublicInputPtr, 1), 0x20)), add(publicInput, 0x20))
        }

        layoutSpecificInit(ctx, publicInput);
    }

    function getPublicInputHash(uint256[] memory publicInput)
        internal
        pure
        override
        returns (bytes32 publicInputHash)
    {
        // The initial seed consists of the first part of publicInput. Specifically, it does not
        // include the page products (which are only known later in the process, as they depend on
        // the values of z and alpha).
        uint256 nPages = publicInput[OFFSET_N_PUBLIC_MEMORY_PAGES];
        uint256 publicInputSizeForHash = 0x20 * getOffsetPageProd(0, nPages);

        assembly {
            publicInputHash := keccak256(add(publicInput, 0x20), publicInputSizeForHash)
        }
    }

    /*
      Computes the value of the public memory quotient:
        numerator / (denominator * padding)
      where:
        numerator = (z - (0 + alpha * 0))^S,
        denominator = \prod_i( z - (addr_i + alpha * value_i) ),
        padding = (z - (padding_addr + alpha * padding_value))^(S - N),
        N is the actual number of public memory cells,
        and S is the number of cells allocated for the public memory (which includes the padding).
    */
    function computePublicMemoryQuotient(uint256[] memory ctx) private view returns (uint256) {
        uint256 nValues = ctx[MM_N_PUBLIC_MEM_ENTRIES];
        uint256 z = ctx[MM_MEMORY__MULTI_COLUMN_PERM__PERM__INTERACTION_ELM];
        uint256 alpha = ctx[MM_MEMORY__MULTI_COLUMN_PERM__HASH_INTERACTION_ELM0];
        // The size that is allocated to the public memory.
        uint256 publicMemorySize = safeDiv(ctx[MM_TRACE_LENGTH], PUBLIC_MEMORY_STEP);

        require(nValues < 0x1000000, "Overflow protection failed.");
        require(nValues <= publicMemorySize, "Number of values of public memory is too large.");

        uint256 nPublicMemoryPages = ctx[MM_N_PUBLIC_MEM_PAGES];
        uint256 cumulativeProdsPtr = ctx[MM_PUBLIC_INPUT_PTR] +
            getOffsetPageProd(0, nPublicMemoryPages) *
            0x20;
        uint256 denominator = computePublicMemoryProd(
            cumulativeProdsPtr,
            nPublicMemoryPages,
            K_MODULUS
        );

        // Compute address + alpha * value for the first address-value pair for padding.
        uint256 publicInputPtr = ctx[MM_PUBLIC_INPUT_PTR];
        uint256 paddingAddr;
        uint256 paddingValue;
        assembly {
            let paddingAddrPtr := add(publicInputPtr, mul(0x20, OFFSET_PUBLIC_MEMORY_PADDING_ADDR))
            paddingAddr := mload(paddingAddrPtr)
            paddingValue := mload(add(paddingAddrPtr, 0x20))
        }
        uint256 hash_first_address_value = fadd(paddingAddr, fmul(paddingValue, alpha));

        // Pad the denominator with the shifted value of hash_first_address_value.
        uint256 denom_pad = fpow(fsub(z, hash_first_address_value), publicMemorySize - nValues);
        denominator = fmul(denominator, denom_pad);

        // Calculate the numerator.
        uint256 numerator = fpow(z, publicMemorySize);

        // Compute the final result: numerator * denominator^(-1).
        return fmul(numerator, inverse(denominator));
    }

    /*
      Computes the cumulative product of the public memory cells:
        \prod_i( z - (addr_i + alpha * value_i) ).

      publicMemoryPtr is an array of nValues pairs (address, value).
      z and alpha are the perm and hash interaction elements required to calculate the product.
    */
    function computePublicMemoryProd(
        uint256 cumulativeProdsPtr,
        uint256 nPublicMemoryPages,
        uint256 prime
    ) private pure returns (uint256 res) {
        assembly {
            let lastPtr := add(cumulativeProdsPtr, mul(nPublicMemoryPages, 0x20))
            res := 1
            for {
                let ptr := cumulativeProdsPtr
            } lt(ptr, lastPtr) {
                ptr := add(ptr, 0x20)
            } {
                res := mulmod(res, mload(ptr), prime)
            }
        }
    }

    /*
      Verifies that all the information on each public memory page (size, hash, prod, and possibly
      address) is consistent with z and alpha, by checking that the corresponding facts were
      registered on memoryPageFactRegistry.
    */
    function verifyMemoryPageFacts(uint256[] memory ctx) private view {
        uint256 nPublicMemoryPages = ctx[MM_N_PUBLIC_MEM_PAGES];

        for (uint256 page = 0; page < nPublicMemoryPages; page++) {
            // Fetch page values from the public input (hash, product and size).
            uint256 memoryHashPtr = ctx[MM_PUBLIC_INPUT_PTR] + getOffsetPageHash(page) * 0x20;
            uint256 memoryHash;

            uint256 prodPtr = ctx[MM_PUBLIC_INPUT_PTR] +
                getOffsetPageProd(page, nPublicMemoryPages) *
                0x20;
            uint256 prod;

            uint256 pageSizePtr = ctx[MM_PUBLIC_INPUT_PTR] + getOffsetPageSize(page) * 0x20;
            uint256 pageSize;

            assembly {
                pageSize := mload(pageSizePtr)
                prod := mload(prodPtr)
                memoryHash := mload(memoryHashPtr)
            }

            uint256 pageAddr = 0;
            if (page > 0) {
                uint256 pageAddrPtr = ctx[MM_PUBLIC_INPUT_PTR] + getOffsetPageAddr(page) * 0x20;
                assembly {
                    pageAddr := mload(pageAddrPtr)
                }
            }

            // Verify that a corresponding fact is registered attesting to the consistency of the page
            // information with z and alpha.
            bytes32 factHash = keccak256(
                abi.encodePacked(
                    page == 0 ? REGULAR_PAGE : CONTINUOUS_PAGE,
                    K_MODULUS,
                    pageSize,
                    /*z=*/
                    ctx[MM_INTERACTION_ELEMENTS],
                    /*alpha=*/
                    ctx[MM_INTERACTION_ELEMENTS + 1],
                    prod,
                    memoryHash,
                    pageAddr
                )
            );

            require( // NOLINT: calls-loop.
                memoryPageFactRegistry.isValid(factHash),
                "Memory page fact was not registered."
            );
        }
    }

    /*
      Checks that the trace and the composition agree at oodsPoint, assuming the prover provided us
      with the proper evaluations.

      Later, we will use boundary constraints to check that those evaluations are actually
      consistent with the committed trace and composition polynomials.
    */
    function oodsConsistencyCheck(uint256[] memory ctx) internal view override {
        verifyMemoryPageFacts(ctx);
        ctx[MM_MEMORY__MULTI_COLUMN_PERM__PERM__INTERACTION_ELM] = ctx[MM_INTERACTION_ELEMENTS];
        ctx[MM_MEMORY__MULTI_COLUMN_PERM__HASH_INTERACTION_ELM0] = ctx[MM_INTERACTION_ELEMENTS + 1];
        ctx[MM_RC16__PERM__INTERACTION_ELM] = ctx[MM_INTERACTION_ELEMENTS + 2];
        {
            uint256 public_memory_prod = computePublicMemoryQuotient(ctx);
            ctx[MM_MEMORY__MULTI_COLUMN_PERM__PERM__PUBLIC_MEMORY_PROD] = public_memory_prod;
        }
        prepareForOodsCheck(ctx);

        uint256 compositionFromTraceValue;
        address lconstraintPoly = address(constraintPoly);
        uint256 offset = 0x20 * (1 + MM_CONSTRAINT_POLY_ARGS_START);
        uint256 size = 0x20 * (MM_CONSTRAINT_POLY_ARGS_END - MM_CONSTRAINT_POLY_ARGS_START);
        assembly {
            // Call CpuConstraintPoly contract.
            let p := mload(0x40)
            if iszero(staticcall(not(0), lconstraintPoly, add(ctx, offset), size, p, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            compositionFromTraceValue := mload(p)
        }

        uint256 claimedComposition = fadd(
            ctx[MM_COMPOSITION_OODS_VALUES],
            fmul(ctx[MM_OODS_POINT], ctx[MM_COMPOSITION_OODS_VALUES + 1])
        );

        require(
            compositionFromTraceValue == claimedComposition,
            "claimedComposition does not match trace"
        );
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IQueryableFactRegistry.sol";

contract FactRegistry is IQueryableFactRegistry {
    // Mapping: fact hash -> true.
    mapping(bytes32 => bool) private verifiedFact;

    // Indicates whether the Fact Registry has at least one fact registered.
    bool anyFactRegistered = false;

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact) external view override returns (bool) {
        return _factCheck(fact);
    }

    /*
      This is an internal method to check if the fact is already registered.
      In current implementation of FactRegistry it's identical to isValid().
      But the check is against the local fact registry,
      So for a derived referral fact registry, it's not the same.
    */
    function _factCheck(bytes32 fact) internal view returns (bool) {
        return verifiedFact[fact];
    }

    function registerFact(bytes32 factHash) internal {
        // This function stores the fact hash in the mapping.
        verifiedFact[factHash] = true;

        // Mark first time off.
        if (!anyFactRegistered) {
            anyFactRegistered = true;
        }
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact() external view override returns (bool) {
        return anyFactRegistered;
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MemoryMap.sol";
import "MemoryAccessUtils.sol";
import "FriLayer.sol";
import "HornerEvaluator.sol";

/*
  This contract computes and verifies all the FRI layer, one by one. The final layer is verified
  by evaluating the fully committed polynomial, and requires specific handling.
*/
contract Fri is MemoryMap, MemoryAccessUtils, HornerEvaluator, FriLayer {
    function verifyLastLayer(uint256[] memory ctx, uint256 nPoints) private view {
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 groupOrderMinusOne = friLastLayerDegBound * ctx[MM_BLOW_UP_FACTOR] - 1;
        uint256 coefsStart = ctx[MM_FRI_LAST_LAYER_PTR];

        for (uint256 i = 0; i < nPoints; i++) {
            uint256 point = ctx[MM_FRI_QUEUE + FRI_QUEUE_SLOT_SIZE * i + 2];
            // Invert point using inverse(point) == fpow(point, ord(point) - 1).

            point = fpow(point, groupOrderMinusOne);
            require(
                hornerEval(coefsStart, point, friLastLayerDegBound) ==
                    ctx[MM_FRI_QUEUE + FRI_QUEUE_SLOT_SIZE * i + 1],
                "Bad Last layer value."
            );
        }
    }

    /*
      Verifies FRI layers.

      See FriLayer for the descriptions of the FRI context and FRI queue.
    */
    function friVerifyLayers(uint256[] memory ctx) internal view virtual {
        uint256 friCtx = getPtr(ctx, MM_FRI_CTX);
        require(
            MAX_SUPPORTED_FRI_STEP_SIZE == FRI_MAX_STEP_SIZE,
            "MAX_STEP_SIZE is inconsistent in MemoryMap.sol and FriLayer.sol"
        );
        initFriGroups(friCtx);
        uint256 channelPtr = getChannelPtr(ctx);
        uint256 merkleQueuePtr = getMerkleQueuePtr(ctx);

        uint256 friStep = 1;
        uint256 nLiveQueries = ctx[MM_N_UNIQUE_QUERIES];

        // Add 0 at the end of the queries array to avoid empty array check in readNextElment.
        ctx[MM_FRI_QUERIES_DELIMITER] = 0;

        // Rather than converting all the values from Montgomery to standard form,
        // we can just pretend that the values are in standard form but all
        // the committed polynomials are multiplied by MontgomeryR.
        //
        // The values in the proof are already multiplied by MontgomeryR,
        // but the inputs from the OODS oracle need to be fixed.
        for (uint256 i = 0; i < nLiveQueries; i++) {
            ctx[MM_FRI_QUEUE + FRI_QUEUE_SLOT_SIZE * i + 1] = fmul(
                ctx[MM_FRI_QUEUE + FRI_QUEUE_SLOT_SIZE * i + 1],
                K_MONTGOMERY_R
            );
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);

        uint256[] memory friStepSizes = getFriStepSizes(ctx);
        uint256 nFriSteps = friStepSizes.length;
        while (friStep < nFriSteps) {
            uint256 friCosetSize = 2**friStepSizes[friStep];

            nLiveQueries = computeNextLayer(
                channelPtr,
                friQueue,
                merkleQueuePtr,
                nLiveQueries,
                friCtx,
                ctx[MM_FRI_EVAL_POINTS + friStep],
                friCosetSize
            );

            // Layer is done, verify the current layer and move to next layer.
            // ctx[mmMerkleQueue: merkleQueueIdx) holds the indices
            // and values of the merkle leaves that need verification.
            verifyMerkle(
                channelPtr,
                merkleQueuePtr,
                bytes32(ctx[MM_FRI_COMMITMENTS + friStep - 1]),
                nLiveQueries
            );

            friStep++;
        }

        verifyLastLayer(ctx, nLiveQueries);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MerkleVerifier.sol";
import "FriTransform.sol";

/*
  The main component of FRI is the FRI step which takes
  the i-th layer evaluations on a coset c*<g> and produces a single evaluation in layer i+1.

  To this end we have a friCtx that holds the following data:
  evaluations:    holds the evaluations on the coset we are currently working on.
  group:          holds the group <g> in bit reversed order.
  halfInvGroup:   holds the group <g^-1>/<-1> in bit reversed order.
                  (We only need half of the inverse group)

  Note that due to the bit reversed order, a prefix of size 2^k of either group
  or halfInvGroup has the same structure (but for a smaller group).
*/
contract FriLayer is MerkleVerifier, FriTransform {
    event LogGas(string name, uint256 val);

    uint256 internal constant MAX_COSET_SIZE = 2**FRI_MAX_STEP_SIZE;
    // Generator of the group of size MAX_COSET_SIZE: GENERATOR_VAL**((K_MODULUS - 1)/MAX_COSET_SIZE).
    uint256 internal constant FRI_GROUP_GEN =
        0x5ec467b88826aba4537602d514425f3b0bdf467bbf302458337c45f6021e539;

    uint256 internal constant FRI_GROUP_SIZE = 0x20 * MAX_COSET_SIZE;
    uint256 internal constant FRI_CTX_TO_COSET_EVALUATIONS_OFFSET = 0;
    uint256 internal constant FRI_CTX_TO_FRI_GROUP_OFFSET = FRI_GROUP_SIZE;
    uint256 internal constant FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET =
        FRI_CTX_TO_FRI_GROUP_OFFSET + FRI_GROUP_SIZE;

    uint256 internal constant FRI_CTX_SIZE =
        FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET + (FRI_GROUP_SIZE / 2);

    /*
      The FRI queue is an array of triplets (query index, FRI value, FRI inversed point).
         'query index' is an adjust query index,
            see adjustQueryIndicesAndPrepareEvalPoints for detail.
         'FRI value' is the expected committed value at query index.
         'FRI inversed point' is evaluation point corresponding to query index i.e.
            inverse(
               fpow(layerGenerator, bitReverse(query index - (1 << logLayerSize), logLayerSize)).
    */
    uint256 internal constant FRI_QUEUE_SLOT_SIZE = 3;
    // FRI_QUEUE_SLOT_SIZE_IN_BYTES cannot reference FRI_QUEUE_SLOT_SIZE as only direct constants
    // are supported in assembly.
    uint256 internal constant FRI_QUEUE_SLOT_SIZE_IN_BYTES = 3 * 0x20;

    /*
      Gathers the "cosetSize" elements that belong the coset of the first element in the FRI queue.
      The elements are written to 'evaluationsOnCosetPtr'.

      The coset elements are read either from the FriQueue or from the verifier channel
      depending on whether the required element are in queue or not.

      Returns
        newFriQueueHead - The update FRI queue head i.e.
          friQueueHead + FRI_QUEUE_SLOT_SIZE_IN_BYTES * (# elements that were taken from the queue).
        cosetIdx - the start index of the coset that was gathered.
        cosetOffset - the xInv field element that corresponds to cosetIdx.
    */
    function gatherCosetInputs(
        uint256 channelPtr,
        uint256 friGroupPtr,
        uint256 evaluationsOnCosetPtr,
        uint256 friQueueHead,
        uint256 cosetSize
    )
        internal
        pure
        returns (
            uint256 newFriQueueHead,
            uint256 cosetIdx,
            uint256 cosetOffset
        )
    {
        assembly {
            let queueItemIdx := mload(friQueueHead)
            // The coset index is represented by the most significant bits of the queue item index.
            cosetIdx := and(queueItemIdx, not(sub(cosetSize, 1)))
            let nextCosetIdx := add(cosetIdx, cosetSize)

            // Get the algebraic coset offset:
            // I.e. given c*g^(-k) compute c, where
            //      g is the generator of the coset group.
            //      k is bitReverse(offsetWithinCoset, log2(cosetSize)).
            //
            // To do this we multiply the algebraic coset offset at the top of the queue (c*g^(-k))
            // by the group element that corresponds to the index inside the coset (g^k).
            cosetOffset := mulmod(
                // (c*g^(-k))=
                mload(add(friQueueHead, 0x40)),
                // (g^k)=
                mload(
                    add(
                        friGroupPtr,
                        mul(
                            // offsetWithinCoset=
                            sub(queueItemIdx, cosetIdx),
                            0x20
                        )
                    )
                ),
                K_MODULUS
            )

            let proofPtr := mload(channelPtr)

            for {
                let index := cosetIdx
            } lt(index, nextCosetIdx) {
                index := add(index, 1)
            } {
                // Inline channel operation:
                // Assume we are going to read the next element from the proof.
                // If this is not the case add(proofPtr, 0x20) will be reverted.
                let fieldElementPtr := proofPtr
                proofPtr := add(proofPtr, 0x20)

                // Load the next index from the queue and check if it is our sibling.
                if eq(index, queueItemIdx) {
                    // Take element from the queue rather than from the proof
                    // and convert it back to Montgomery form for Merkle verification.
                    fieldElementPtr := add(friQueueHead, 0x20)

                    // Revert the read from proof.
                    proofPtr := sub(proofPtr, 0x20)

                    // Reading the next index here is safe due to the
                    // delimiter after the queries.
                    friQueueHead := add(friQueueHead, FRI_QUEUE_SLOT_SIZE_IN_BYTES)
                    queueItemIdx := mload(friQueueHead)
                }

                // Note that we apply the modulo operation to convert the field elements we read
                // from the proof to canonical representation (in the range [0, K_MODULUS - 1]).
                mstore(evaluationsOnCosetPtr, mod(mload(fieldElementPtr), K_MODULUS))
                evaluationsOnCosetPtr := add(evaluationsOnCosetPtr, 0x20)
            }

            mstore(channelPtr, proofPtr)
        }
        newFriQueueHead = friQueueHead;
    }

    /*
      Returns the bit reversal of num assuming it has the given number of bits.
      For example, if we have numberOfBits = 6 and num = (0b)1101 == (0b)001101,
      the function will return (0b)101100.
    */
    function bitReverse(uint256 num, uint256 numberOfBits)
        internal
        pure
        returns (uint256 numReversed)
    {
        assert((numberOfBits == 256) || (num < 2**numberOfBits));
        uint256 n = num;
        uint256 r = 0;
        for (uint256 k = 0; k < numberOfBits; k++) {
            r = (r * 2) | (n % 2);
            n = n / 2;
        }
        return r;
    }

    /*
      Initializes the FRI group and half inv group in the FRI context.
    */
    function initFriGroups(uint256 friCtx) internal view {
        uint256 friGroupPtr = friCtx + FRI_CTX_TO_FRI_GROUP_OFFSET;
        uint256 friHalfInvGroupPtr = friCtx + FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET;

        // FRI_GROUP_GEN is the coset generator.
        // Raising it to the (MAX_COSET_SIZE - 1) power gives us the inverse.
        uint256 genFriGroup = FRI_GROUP_GEN;

        uint256 genFriGroupInv = fpow(genFriGroup, (MAX_COSET_SIZE - 1));

        uint256 lastVal = ONE_VAL;
        uint256 lastValInv = ONE_VAL;
        assembly {
            // ctx[mmHalfFriInvGroup + 0] = ONE_VAL;
            mstore(friHalfInvGroupPtr, lastValInv)
            // ctx[mmFriGroup + 0] = ONE_VAL;
            mstore(friGroupPtr, lastVal)
            // ctx[mmFriGroup + 1] = fsub(0, ONE_VAL);
            mstore(add(friGroupPtr, 0x20), sub(K_MODULUS, lastVal))
        }

        // To compute [1, -1 (== g^n/2), g^n/4, -g^n/4, ...]
        // we compute half the elements and derive the rest using negation.
        uint256 halfCosetSize = MAX_COSET_SIZE / 2;
        for (uint256 i = 1; i < halfCosetSize; i++) {
            lastVal = fmul(lastVal, genFriGroup);
            lastValInv = fmul(lastValInv, genFriGroupInv);
            uint256 idx = bitReverse(i, FRI_MAX_STEP_SIZE - 1);

            assembly {
                // ctx[mmHalfFriInvGroup + idx] = lastValInv;
                mstore(add(friHalfInvGroupPtr, mul(idx, 0x20)), lastValInv)
                // ctx[mmFriGroup + 2*idx] = lastVal;
                mstore(add(friGroupPtr, mul(idx, 0x40)), lastVal)
                // ctx[mmFriGroup + 2*idx + 1] = fsub(0, lastVal);
                mstore(add(friGroupPtr, add(mul(idx, 0x40), 0x20)), sub(K_MODULUS, lastVal))
            }
        }
    }

    /*
      Computes the FRI step with eta = log2(friCosetSize) for all the live queries.

      The inputs for the current layer are read from the FRI queue and the inputs
      for the next layer are written to the same queue (overwriting the input).
      See friVerifyLayers for the description for the FRI queue.

      The function returns the number of live queries remaining after computing the FRI step.

      The number of live queries decreases whenever multiple query points in the same
      coset are reduced to a single query in the next FRI layer.

      As the function computes the next layer it also collects that data from
      the previous layer for Merkle verification.
    */
    function computeNextLayer(
        uint256 channelPtr,
        uint256 friQueuePtr,
        uint256 merkleQueuePtr,
        uint256 nQueries,
        uint256 friCtx,
        uint256 friEvalPoint,
        uint256 friCosetSize
    ) internal pure returns (uint256 nLiveQueries) {
        uint256 evaluationsOnCosetPtr = friCtx + FRI_CTX_TO_COSET_EVALUATIONS_OFFSET;

        // The inputs are read from the Fri queue and the result is written same queue.
        // The inputs are never overwritten since gatherCosetInputs reads at least one element and
        // transformCoset writes exactly one element.
        uint256 inputPtr = friQueuePtr;
        uint256 inputEnd = inputPtr + (FRI_QUEUE_SLOT_SIZE_IN_BYTES * nQueries);
        uint256 ouputPtr = friQueuePtr;

        do {
            uint256 cosetOffset;
            uint256 index;
            (inputPtr, index, cosetOffset) = gatherCosetInputs(
                channelPtr,
                friCtx + FRI_CTX_TO_FRI_GROUP_OFFSET,
                evaluationsOnCosetPtr,
                inputPtr,
                friCosetSize
            );

            // Compute the index of the coset evaluations in the Merkle queue.
            index /= friCosetSize;

            // Add (index, keccak256(evaluationsOnCoset)) to the Merkle queue.
            assembly {
                mstore(merkleQueuePtr, index)
                mstore(
                    add(merkleQueuePtr, 0x20),
                    and(COMMITMENT_MASK, keccak256(evaluationsOnCosetPtr, mul(0x20, friCosetSize)))
                )
            }
            merkleQueuePtr += MERKLE_SLOT_SIZE_IN_BYTES;

            (uint256 friValue, uint256 FriInversedPoint) = transformCoset(
                friCtx + FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET,
                evaluationsOnCosetPtr,
                cosetOffset,
                friEvalPoint,
                friCosetSize
            );

            // Add (index, friValue, FriInversedPoint) to the FRI queue.
            // Note that the index in the Merkle queue is also the index in the next FRI layer.
            assembly {
                mstore(ouputPtr, index)
                mstore(add(ouputPtr, 0x20), friValue)
                mstore(add(ouputPtr, 0x40), FriInversedPoint)
            }
            ouputPtr += FRI_QUEUE_SLOT_SIZE_IN_BYTES;
        } while (inputPtr < inputEnd);

        // Return the current number of live queries.
        return (ouputPtr - friQueuePtr) / FRI_QUEUE_SLOT_SIZE_IN_BYTES;
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "FactRegistry.sol";
import "FriLayer.sol";

contract FriStatementContract is FriLayer, FactRegistry {
    /*
      Compute a single FRI layer of size friStepSize at evaluationPoint starting from input
      friQueue, and the extra witnesses in the "proof" channel. Also check that the input and
      witnesses belong to a Merkle tree with root expectedRoot, again using witnesses from "proof".
      After verification, register the FRI fact hash, which is:
      keccak256(
          evaluationPoint,
          friStepSize,
          keccak256(friQueue_input),
          keccak256(friQueue_output),  // The FRI queue after proccessing the FRI layer
          expectedRoot
      )

      Note that this function is used as external, but declared public to avoid copying the arrays.
    */
    function verifyFRI(
        uint256[] memory proof,
        uint256[] memory friQueue,
        uint256 evaluationPoint,
        uint256 friStepSize,
        uint256 expectedRoot
    ) public {
        require(friStepSize <= FRI_MAX_STEP_SIZE, "FRI step size too large");

        // Verify evaluation point within valid range.
        require(evaluationPoint < K_MODULUS, "INVALID_EVAL_POINT");

        // Validate the FRI queue.
        validateFriQueue(friQueue);

        uint256 mmFriCtxSize = FRI_CTX_SIZE;
        uint256 nQueries = friQueue.length / 3; // NOLINT: divide-before-multiply.
        uint256 merkleQueuePtr;
        uint256 friQueuePtr;
        uint256 channelPtr;
        uint256 friCtx;
        uint256 dataToHash;

        // Allocate memory queues: channelPtr, merkleQueue, friCtx, dataToHash.
        assembly {
            friQueuePtr := add(friQueue, 0x20)
            channelPtr := mload(0x40) // Free pointer location.
            mstore(channelPtr, add(proof, 0x20))
            merkleQueuePtr := add(channelPtr, 0x20)
            friCtx := add(merkleQueuePtr, mul(0x40, nQueries))
            dataToHash := add(friCtx, mmFriCtxSize)
            mstore(0x40, add(dataToHash, 0xa0)) // Advance free pointer.

            mstore(dataToHash, evaluationPoint)
            mstore(add(dataToHash, 0x20), friStepSize)
            mstore(add(dataToHash, 0x80), expectedRoot)

            // Hash FRI inputs and add to dataToHash.
            mstore(add(dataToHash, 0x40), keccak256(friQueuePtr, mul(0x60, nQueries)))
        }

        initFriGroups(friCtx);

        nQueries = computeNextLayer(
            channelPtr,
            friQueuePtr,
            merkleQueuePtr,
            nQueries,
            friCtx,
            evaluationPoint,
            2**friStepSize /* friCosetSize = 2**friStepSize */
        );

        verifyMerkle(channelPtr, merkleQueuePtr, bytes32(expectedRoot), nQueries);

        bytes32 factHash;
        assembly {
            // Hash FRI outputs and add to dataToHash.
            mstore(add(dataToHash, 0x60), keccak256(friQueuePtr, mul(0x60, nQueries)))
            factHash := keccak256(dataToHash, 0xa0)
        }

        registerFact(factHash);
    }

    /*
      Validates the entries of the FRI queue.

      The friQueue should have of 3*nQueries + 1 elements, beginning with nQueries triplets
      of the form (query_index, FRI_value, FRI_inverse_point), and ending with a single buffer
      cell set to 0, which is accessed and read during the computation of the FRI layer.  

      Queries need to be in the range [2**height .. 2**(height+1)-1] and strictly incrementing.
      The FRI values and inverses need to be smaller than K_MODULUS.
    */
    function validateFriQueue(uint256[] memory friQueue) private pure {
        require(
            friQueue.length % 3 == 1,
            "FRI Queue must be composed of triplets plus one delimiter cell"
        );
        require(friQueue.length >= 4, "No query to process");

        // Force delimiter cell to 0, this is cheaper then asserting it.
        friQueue[friQueue.length - 1] = 0;

        // We need to check that Qi+1 > Qi for each i,
        // Given that the queries are sorted the height range requirement can be validated by
        // checking that (Q1 ^ Qn) < Q1.
        // This check affirms that all queries are within the same logarithmic step.
        uint256 nQueries = friQueue.length / 3; // NOLINT: divide-before-multiply.
        uint256 prevQuery = 0;
        for (uint256 i = 0; i < nQueries; i++) {
            // Verify that queries are strictly incrementing.
            require(friQueue[3 * i] > prevQuery, "INVALID_QUERY_VALUE");
            // Verify FRI value and inverse are within valid range.
            require(friQueue[3 * i + 1] < K_MODULUS, "INVALID_FRI_VALUE");
            require(friQueue[3 * i + 2] < K_MODULUS, "INVALID_FRI_INVERSE_POINT");
            prevQuery = friQueue[3 * i];
        }

        // Verify all queries are on the same logarithmic step.
        // NOLINTNEXTLINE: divide-before-multiply.
        require((friQueue[0] ^ friQueue[3 * nQueries - 3]) < friQueue[0], "INVALID_QUERIES_RANGE");
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MemoryMap.sol";
import "MemoryAccessUtils.sol";
import "FriStatementContract.sol";
import "HornerEvaluator.sol";
import "VerifierChannel.sol";

/*
  This contract verifies all the FRI layer, one by one, using the FriStatementContract.
  The first layer is computed from decommitments, the last layer is computed by evaluating the
  fully committed polynomial, and the mid-layers are provided in the proof only as hashed data.
*/
abstract contract FriStatementVerifier is
    MemoryMap,
    MemoryAccessUtils,
    VerifierChannel,
    HornerEvaluator
{
    FriStatementContract friStatementContract;

    constructor(address friStatementContractAddress) internal {
        friStatementContract = FriStatementContract(friStatementContractAddress);
    }

    /*
      Fast-forwards the queries and invPoints of the friQueue from before the first layer to after
      the last layer, computes the last FRI layer using horner evaluations, then returns the hash
      of the final FriQueue.
    */
    function computeLastLayerHash(
        uint256[] memory ctx,
        uint256 nPoints,
        uint256 sumOfStepSizes
    ) private view returns (bytes32 lastLayerHash) {
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 groupOrderMinusOne = friLastLayerDegBound * ctx[MM_BLOW_UP_FACTOR] - 1;
        uint256 exponent = 1 << sumOfStepSizes;
        uint256 curPointIndex = 0;
        uint256 prevQuery = 0;
        uint256 coefsStart = ctx[MM_FRI_LAST_LAYER_PTR];

        for (uint256 i = 0; i < nPoints; i++) {
            uint256 query = ctx[MM_FRI_QUEUE + 3 * i] >> sumOfStepSizes;
            if (query == prevQuery) {
                continue;
            }
            ctx[MM_FRI_QUEUE + 3 * curPointIndex] = query;
            prevQuery = query;

            uint256 point = fpow(ctx[MM_FRI_QUEUE + 3 * i + 2], exponent);
            ctx[MM_FRI_QUEUE + 3 * curPointIndex + 2] = point;
            // Invert point using inverse(point) == fpow(point, ord(point) - 1).

            point = fpow(point, groupOrderMinusOne);
            ctx[MM_FRI_QUEUE + 3 * curPointIndex + 1] = hornerEval(
                coefsStart,
                point,
                friLastLayerDegBound
            );

            curPointIndex++;
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        assembly {
            lastLayerHash := keccak256(friQueue, mul(curPointIndex, 0x60))
        }
    }

    /*
      Verifies that FRI layers consistent with the computed first and last FRI layers
      have been registered in the FriStatementContract.
    */
    function friVerifyLayers(uint256[] memory ctx) internal view virtual {
        uint256 channelPtr = getChannelPtr(ctx);
        uint256 nQueries = ctx[MM_N_UNIQUE_QUERIES];

        // Rather than converting all the values from Montgomery to standard form,
        // we can just pretend that the values are in standard form but all
        // the committed polynomials are multiplied by MontgomeryR.
        //
        // The values in the proof are already multiplied by MontgomeryR,
        // but the inputs from the OODS oracle need to be fixed.
        for (uint256 i = 0; i < nQueries; i++) {
            ctx[MM_FRI_QUEUE + 3 * i + 1] = fmul(ctx[MM_FRI_QUEUE + 3 * i + 1], K_MONTGOMERY_R);
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 inputLayerHash;
        assembly {
            inputLayerHash := keccak256(friQueue, mul(nQueries, 0x60))
        }

        uint256[] memory friStepSizes = getFriStepSizes(ctx);
        uint256 nFriInnerLayers = friStepSizes.length - 1;
        uint256 friStep = 1;
        uint256 sumOfStepSizes = friStepSizes[1];
        uint256[5] memory dataToHash;
        while (friStep < nFriInnerLayers) {
            uint256 outputLayerHash = uint256(readBytes(channelPtr, true));
            dataToHash[0] = ctx[MM_FRI_EVAL_POINTS + friStep];
            dataToHash[1] = friStepSizes[friStep];
            dataToHash[2] = inputLayerHash;
            dataToHash[3] = outputLayerHash;
            dataToHash[4] = ctx[MM_FRI_COMMITMENTS + friStep - 1];

            // Verify statement is registered.
            require( // NOLINT: calls-loop.
                friStatementContract.isValid(keccak256(abi.encodePacked(dataToHash))),
                "INVALIDATED_FRI_STATEMENT"
            );

            inputLayerHash = outputLayerHash;

            friStep++;
            sumOfStepSizes += friStepSizes[friStep];
        }

        dataToHash[0] = ctx[MM_FRI_EVAL_POINTS + friStep];
        dataToHash[1] = friStepSizes[friStep];
        dataToHash[2] = inputLayerHash;
        dataToHash[3] = uint256(computeLastLayerHash(ctx, nQueries, sumOfStepSizes));
        dataToHash[4] = ctx[MM_FRI_COMMITMENTS + friStep - 1];

        require(
            friStatementContract.isValid(keccak256(abi.encodePacked(dataToHash))),
            "INVALIDATED_FRI_STATEMENT"
        );
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "PrimeFieldElement0.sol";

/*
  The FRI transform for a coset of size 2 (x, -x) takes the inputs
  x, f(x), f(-x) and evalPoint
  and returns
  (f(x) + f(-x) + evalPoint*(f(x) - f(-x))/x) / 2.

  The implementation here modifies this transformation slightly:
  1. Since dividing by 2 does not affect the degree, it is omitted here (and in the prover).
  2. The division by x is replaced by multiplication by x^-1, x^-1 is passed as input to the
     transform and (x^-1)^2 is returned as it will be needed in the next layer.

  To apply the transformation on a larger coset the transformation above is used multiple times
  with the evaluation points: evalPoint, evalPoint^2, evalPoint^4, ...
*/
contract FriTransform is PrimeFieldElement0 {
    // The supported step sizes are 2, 3 and 4.
    uint256 internal constant FRI_MIN_STEP_SIZE = 2;
    uint256 internal constant FRI_MAX_STEP_SIZE = 4;

    // The largest power of 2 multiple of K_MODULUS that fits in a uint256.
    // The value is given as a constant because "Only direct number constants and references to such
    // constants are supported by inline assembly."
    // This constant is used in places where we delay the module operation to reduce gas usage.
    uint256 internal constant K_MODULUS_TIMES_16 = (
        0x8000000000000110000000000000000000000000000000000000000000000010
    );

    /*
      Performs a FRI transform for the coset of size friFoldedCosetSize that begins at index.

      Assumes the evaluations on the coset are stored at 'evaluationsOnCosetPtr'.
      See gatherCosetInputs for more detail.
    */
    function transformCoset(
        uint256 friHalfInvGroupPtr,
        uint256 evaluationsOnCosetPtr,
        uint256 cosetOffset,
        uint256 friEvalPoint,
        uint256 friCosetSize
    ) internal pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        // Compare to expected FRI step sizes in order of likelihood, step size 3 being most common.
        if (friCosetSize == 8) {
            return
                transformCosetOfSize8(
                    friHalfInvGroupPtr,
                    evaluationsOnCosetPtr,
                    cosetOffset,
                    friEvalPoint
                );
        } else if (friCosetSize == 4) {
            return
                transformCosetOfSize4(
                    friHalfInvGroupPtr,
                    evaluationsOnCosetPtr,
                    cosetOffset,
                    friEvalPoint
                );
        } else if (friCosetSize == 16) {
            return
                transformCosetOfSize16(
                    friHalfInvGroupPtr,
                    evaluationsOnCosetPtr,
                    cosetOffset,
                    friEvalPoint
                );
        } else {
            require(false, "Only step sizes of 2, 3 or 4 are supported.");
        }
    }

    /*
      Applies 2 + 1 FRI transformations to a coset of size 2^2.

      evaluations on coset:                    f0 f1  f2 f3
      ----------------------------------------  \ / -- \ / -----------
                                                 f0    f2
      ------------------------------------------- \ -- / -------------
      nextLayerValue:                               f0

      For more detail, see description of the FRI transformations at the top of this file.
    */
    function transformCosetOfSize4(
        uint256 friHalfInvGroupPtr,
        uint256 evaluationsOnCosetPtr,
        uint256 cosetOffset_,
        uint256 friEvalPoint
    ) private pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, K_MODULUS)

            let f0 := mload(evaluationsOnCosetPtr)
            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(
                    add(f0, f1),
                    mulmod(
                        friEvalPointDivByX,
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS, f1)
                        ),
                        K_MODULUS
                    )
                )
            }

            let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
            {
                let f3 := mload(add(evaluationsOnCosetPtr, 0x60))
                f2 := addmod(
                    add(f2, f3),
                    mulmod(
                        add(
                            f2,
                            // -fMinusX
                            sub(K_MODULUS, f3)
                        ),
                        mulmod(mload(add(friHalfInvGroupPtr, 0x20)), friEvalPointDivByX, K_MODULUS),
                        K_MODULUS
                    ),
                    K_MODULUS
                )
            }

            {
                let newXInv := mulmod(cosetOffset_, cosetOffset_, K_MODULUS)
                nextXInv := mulmod(newXInv, newXInv, K_MODULUS)
            }

            // f0 + f2 < 4P ( = 3 + 1).
            nextLayerValue := addmod(
                add(f0, f2),
                mulmod(
                    mulmod(friEvalPointDivByX, friEvalPointDivByX, K_MODULUS),
                    add(
                        f0,
                        // -fMinusX
                        sub(K_MODULUS, f2)
                    ),
                    K_MODULUS
                ),
                K_MODULUS
            )
        }
    }

    /*
      Applies 4 + 2 + 1 FRI transformations to a coset of size 2^3.

      For more detail, see description of the FRI transformations at the top of this file.
    */
    function transformCosetOfSize8(
        uint256 friHalfInvGroupPtr,
        uint256 evaluationsOnCosetPtr,
        uint256 cosetOffset_,
        uint256 friEvalPoint
    ) private pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let f0 := mload(evaluationsOnCosetPtr)

            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, K_MODULUS)
            let friEvalPointDivByXSquared := mulmod(
                friEvalPointDivByX,
                friEvalPointDivByX,
                K_MODULUS
            )
            let imaginaryUnit := mload(add(friHalfInvGroupPtr, 0x20))

            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(
                    add(f0, f1),
                    mulmod(
                        friEvalPointDivByX,
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS, f1)
                        ),
                        K_MODULUS
                    )
                )
            }
            {
                let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
                {
                    let f3 := mload(add(evaluationsOnCosetPtr, 0x60))

                    // f2 < 3P ( = 1 + 1 + 1).
                    f2 := add(
                        add(f2, f3),
                        mulmod(
                            add(
                                f2,
                                // -fMinusX
                                sub(K_MODULUS, f3)
                            ),
                            mulmod(friEvalPointDivByX, imaginaryUnit, K_MODULUS),
                            K_MODULUS
                        )
                    )
                }

                // f0 < 7P ( = 3 + 3 + 1).
                f0 := add(
                    add(f0, f2),
                    mulmod(
                        friEvalPointDivByXSquared,
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS_TIMES_16, f2)
                        ),
                        K_MODULUS
                    )
                )
            }
            {
                let f4 := mload(add(evaluationsOnCosetPtr, 0x80))
                {
                    let friEvalPointDivByX2 := mulmod(
                        friEvalPointDivByX,
                        mload(add(friHalfInvGroupPtr, 0x40)),
                        K_MODULUS
                    )
                    {
                        let f5 := mload(add(evaluationsOnCosetPtr, 0xa0))

                        // f4 < 3P ( = 1 + 1 + 1).
                        f4 := add(
                            add(f4, f5),
                            mulmod(
                                friEvalPointDivByX2,
                                add(
                                    f4,
                                    // -fMinusX
                                    sub(K_MODULUS, f5)
                                ),
                                K_MODULUS
                            )
                        )
                    }

                    let f6 := mload(add(evaluationsOnCosetPtr, 0xc0))
                    {
                        let f7 := mload(add(evaluationsOnCosetPtr, 0xe0))

                        // f6 < 3P ( = 1 + 1 + 1).
                        f6 := add(
                            add(f6, f7),
                            mulmod(
                                add(
                                    f6,
                                    // -fMinusX
                                    sub(K_MODULUS, f7)
                                ),
                                // friEvalPointDivByX2 * imaginaryUnit ==
                                // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0x60)).
                                mulmod(friEvalPointDivByX2, imaginaryUnit, K_MODULUS),
                                K_MODULUS
                            )
                        )
                    }

                    // f4 < 7P ( = 3 + 3 + 1).
                    f4 := add(
                        add(f4, f6),
                        mulmod(
                            mulmod(friEvalPointDivByX2, friEvalPointDivByX2, K_MODULUS),
                            add(
                                f4,
                                // -fMinusX
                                sub(K_MODULUS_TIMES_16, f6)
                            ),
                            K_MODULUS
                        )
                    )
                }

                // f0, f4 < 7P -> f0 + f4 < 14P && 9P < f0 + (K_MODULUS_TIMES_16 - f4) < 23P.
                nextLayerValue := addmod(
                    add(f0, f4),
                    mulmod(
                        mulmod(friEvalPointDivByXSquared, friEvalPointDivByXSquared, K_MODULUS),
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS_TIMES_16, f4)
                        ),
                        K_MODULUS
                    ),
                    K_MODULUS
                )
            }

            {
                let xInv2 := mulmod(cosetOffset_, cosetOffset_, K_MODULUS)
                let xInv4 := mulmod(xInv2, xInv2, K_MODULUS)
                nextXInv := mulmod(xInv4, xInv4, K_MODULUS)
            }
        }
    }

    /*
      Applies 8 + 4 + 2 + 1 FRI transformations to a coset of size 2^4.
      to obtain a single element.

      For more detail, see description of the FRI transformations at the top of this file.
    */
    function transformCosetOfSize16(
        uint256 friHalfInvGroupPtr,
        uint256 evaluationsOnCosetPtr,
        uint256 cosetOffset_,
        uint256 friEvalPoint
    ) private pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let friEvalPointDivByXTessed
            let f0 := mload(evaluationsOnCosetPtr)

            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, K_MODULUS)
            let imaginaryUnit := mload(add(friHalfInvGroupPtr, 0x20))

            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(
                    add(f0, f1),
                    mulmod(
                        friEvalPointDivByX,
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS, f1)
                        ),
                        K_MODULUS
                    )
                )
            }
            {
                let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
                {
                    let f3 := mload(add(evaluationsOnCosetPtr, 0x60))

                    // f2 < 3P ( = 1 + 1 + 1).
                    f2 := add(
                        add(f2, f3),
                        mulmod(
                            add(
                                f2,
                                // -fMinusX
                                sub(K_MODULUS, f3)
                            ),
                            mulmod(friEvalPointDivByX, imaginaryUnit, K_MODULUS),
                            K_MODULUS
                        )
                    )
                }
                {
                    let friEvalPointDivByXSquared := mulmod(
                        friEvalPointDivByX,
                        friEvalPointDivByX,
                        K_MODULUS
                    )
                    friEvalPointDivByXTessed := mulmod(
                        friEvalPointDivByXSquared,
                        friEvalPointDivByXSquared,
                        K_MODULUS
                    )

                    // f0 < 7P ( = 3 + 3 + 1).
                    f0 := add(
                        add(f0, f2),
                        mulmod(
                            friEvalPointDivByXSquared,
                            add(
                                f0,
                                // -fMinusX
                                sub(K_MODULUS_TIMES_16, f2)
                            ),
                            K_MODULUS
                        )
                    )
                }
            }
            {
                let f4 := mload(add(evaluationsOnCosetPtr, 0x80))
                {
                    let friEvalPointDivByX2 := mulmod(
                        friEvalPointDivByX,
                        mload(add(friHalfInvGroupPtr, 0x40)),
                        K_MODULUS
                    )
                    {
                        let f5 := mload(add(evaluationsOnCosetPtr, 0xa0))

                        // f4 < 3P ( = 1 + 1 + 1).
                        f4 := add(
                            add(f4, f5),
                            mulmod(
                                friEvalPointDivByX2,
                                add(
                                    f4,
                                    // -fMinusX
                                    sub(K_MODULUS, f5)
                                ),
                                K_MODULUS
                            )
                        )
                    }

                    let f6 := mload(add(evaluationsOnCosetPtr, 0xc0))
                    {
                        let f7 := mload(add(evaluationsOnCosetPtr, 0xe0))

                        // f6 < 3P ( = 1 + 1 + 1).
                        f6 := add(
                            add(f6, f7),
                            mulmod(
                                add(
                                    f6,
                                    // -fMinusX
                                    sub(K_MODULUS, f7)
                                ),
                                // friEvalPointDivByX2 * imaginaryUnit ==
                                // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0x60)).
                                mulmod(friEvalPointDivByX2, imaginaryUnit, K_MODULUS),
                                K_MODULUS
                            )
                        )
                    }

                    // f4 < 7P ( = 3 + 3 + 1).
                    f4 := add(
                        add(f4, f6),
                        mulmod(
                            mulmod(friEvalPointDivByX2, friEvalPointDivByX2, K_MODULUS),
                            add(
                                f4,
                                // -fMinusX
                                sub(K_MODULUS_TIMES_16, f6)
                            ),
                            K_MODULUS
                        )
                    )
                }

                // f0 < 15P ( = 7 + 7 + 1).
                f0 := add(
                    add(f0, f4),
                    mulmod(
                        friEvalPointDivByXTessed,
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS_TIMES_16, f4)
                        ),
                        K_MODULUS
                    )
                )
            }
            {
                let f8 := mload(add(evaluationsOnCosetPtr, 0x100))
                {
                    let friEvalPointDivByX4 := mulmod(
                        friEvalPointDivByX,
                        mload(add(friHalfInvGroupPtr, 0x80)),
                        K_MODULUS
                    )
                    {
                        let f9 := mload(add(evaluationsOnCosetPtr, 0x120))

                        // f8 < 3P ( = 1 + 1 + 1).
                        f8 := add(
                            add(f8, f9),
                            mulmod(
                                friEvalPointDivByX4,
                                add(
                                    f8,
                                    // -fMinusX
                                    sub(K_MODULUS, f9)
                                ),
                                K_MODULUS
                            )
                        )
                    }

                    let f10 := mload(add(evaluationsOnCosetPtr, 0x140))
                    {
                        let f11 := mload(add(evaluationsOnCosetPtr, 0x160))
                        // f10 < 3P ( = 1 + 1 + 1).
                        f10 := add(
                            add(f10, f11),
                            mulmod(
                                add(
                                    f10,
                                    // -fMinusX
                                    sub(K_MODULUS, f11)
                                ),
                                // friEvalPointDivByX4 * imaginaryUnit ==
                                // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0xa0)).
                                mulmod(friEvalPointDivByX4, imaginaryUnit, K_MODULUS),
                                K_MODULUS
                            )
                        )
                    }

                    // f8 < 7P ( = 3 + 3 + 1).
                    f8 := add(
                        add(f8, f10),
                        mulmod(
                            mulmod(friEvalPointDivByX4, friEvalPointDivByX4, K_MODULUS),
                            add(
                                f8,
                                // -fMinusX
                                sub(K_MODULUS_TIMES_16, f10)
                            ),
                            K_MODULUS
                        )
                    )
                }
                {
                    let f12 := mload(add(evaluationsOnCosetPtr, 0x180))
                    {
                        let friEvalPointDivByX6 := mulmod(
                            friEvalPointDivByX,
                            mload(add(friHalfInvGroupPtr, 0xc0)),
                            K_MODULUS
                        )
                        {
                            let f13 := mload(add(evaluationsOnCosetPtr, 0x1a0))

                            // f12 < 3P ( = 1 + 1 + 1).
                            f12 := add(
                                add(f12, f13),
                                mulmod(
                                    friEvalPointDivByX6,
                                    add(
                                        f12,
                                        // -fMinusX
                                        sub(K_MODULUS, f13)
                                    ),
                                    K_MODULUS
                                )
                            )
                        }

                        let f14 := mload(add(evaluationsOnCosetPtr, 0x1c0))
                        {
                            let f15 := mload(add(evaluationsOnCosetPtr, 0x1e0))

                            // f14 < 3P ( = 1 + 1 + 1).
                            f14 := add(
                                add(f14, f15),
                                mulmod(
                                    add(
                                        f14,
                                        // -fMinusX
                                        sub(K_MODULUS, f15)
                                    ),
                                    // friEvalPointDivByX6 * imaginaryUnit ==
                                    // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0xe0)).
                                    mulmod(friEvalPointDivByX6, imaginaryUnit, K_MODULUS),
                                    K_MODULUS
                                )
                            )
                        }

                        // f12 < 7P ( = 3 + 3 + 1).
                        f12 := add(
                            add(f12, f14),
                            mulmod(
                                mulmod(friEvalPointDivByX6, friEvalPointDivByX6, K_MODULUS),
                                add(
                                    f12,
                                    // -fMinusX
                                    sub(K_MODULUS_TIMES_16, f14)
                                ),
                                K_MODULUS
                            )
                        )
                    }

                    // f8 < 15P ( = 7 + 7 + 1).
                    f8 := add(
                        add(f8, f12),
                        mulmod(
                            mulmod(friEvalPointDivByXTessed, imaginaryUnit, K_MODULUS),
                            add(
                                f8,
                                // -fMinusX
                                sub(K_MODULUS_TIMES_16, f12)
                            ),
                            K_MODULUS
                        )
                    )
                }

                // f0, f8 < 15P -> f0 + f8 < 30P && 16P < f0 + (K_MODULUS_TIMES_16 - f8) < 31P.
                nextLayerValue := addmod(
                    add(f0, f8),
                    mulmod(
                        mulmod(friEvalPointDivByXTessed, friEvalPointDivByXTessed, K_MODULUS),
                        add(
                            f0,
                            // -fMinusX
                            sub(K_MODULUS_TIMES_16, f8)
                        ),
                        K_MODULUS
                    ),
                    K_MODULUS
                )
            }

            {
                let xInv2 := mulmod(cosetOffset_, cosetOffset_, K_MODULUS)
                let xInv4 := mulmod(xInv2, xInv2, K_MODULUS)
                let xInv8 := mulmod(xInv4, xInv4, K_MODULUS)
                nextXInv := mulmod(xInv8, xInv8, K_MODULUS)
            }
        }
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "PrimeFieldElement0.sol";

contract HornerEvaluator is PrimeFieldElement0 {
    /*
      Computes the evaluation of a polynomial f(x) = sum(a_i * x^i) on the given point.
      The coefficients of the polynomial are given in
        a_0 = coefsStart[0], ..., a_{n-1} = coefsStart[n - 1]
      where n = nCoefs = friLastLayerDegBound. Note that coefsStart is not actually an array but
      a direct pointer.
      The function requires that n is divisible by 8.
    */
    function hornerEval(
        uint256 coefsStart,
        uint256 point,
        uint256 nCoefs
    ) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 prime = PrimeFieldElement0.K_MODULUS;

        require(nCoefs % 8 == 0, "Number of polynomial coefficients must be divisible by 8");
        // Ensure 'nCoefs' is bounded from above as a sanity check
        // (the bound is somewhat arbitrary).
        require(nCoefs < 4096, "No more than 4096 coefficients are supported");

        assembly {
            let coefsPtr := add(coefsStart, mul(nCoefs, 0x20))
            for {

            } gt(coefsPtr, coefsStart) {

            } {
                // Reduce coefsPtr by 8 field elements.
                coefsPtr := sub(coefsPtr, 0x100)

                // Apply 4 Horner steps (result := result * point + coef).
                result := add(
                    mload(add(coefsPtr, 0x80)),
                    mulmod(
                        add(
                            mload(add(coefsPtr, 0xa0)),
                            mulmod(
                                add(
                                    mload(add(coefsPtr, 0xc0)),
                                    mulmod(
                                        add(
                                            mload(add(coefsPtr, 0xe0)),
                                            mulmod(result, point, prime)
                                        ),
                                        point,
                                        prime
                                    )
                                ),
                                point,
                                prime
                            )
                        ),
                        point,
                        prime
                    )
                )

                // Apply 4 additional Horner steps.
                result := add(
                    mload(coefsPtr),
                    mulmod(
                        add(
                            mload(add(coefsPtr, 0x20)),
                            mulmod(
                                add(
                                    mload(add(coefsPtr, 0x40)),
                                    mulmod(
                                        add(
                                            mload(add(coefsPtr, 0x60)),
                                            mulmod(result, point, prime)
                                        ),
                                        point,
                                        prime
                                    )
                                ),
                                point,
                                prime
                            )
                        ),
                        point,
                        prime
                    )
                )
            }
        }

        // Since the last operation was "add" (instead of "addmod"), we need to take result % prime.
        return result % prime;
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract IMerkleVerifier {
    uint256 internal constant MAX_N_MERKLE_VERIFIER_QUERIES = 128;

    // The size of a SLOT in the verifyMerkle queue.
    // Every slot holds a (index, hash) pair.
    uint256 internal constant MERKLE_SLOT_SIZE_IN_BYTES = 0x40;

    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view virtual returns (bytes32 hash);
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IPeriodicColumn {
    function compute(uint256 x) external pure returns (uint256 result);
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {
    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact() external view returns (bool);
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract IStarkVerifier {
    function verifyProof(
        uint256[] memory proofParams,
        uint256[] memory proof,
        uint256[] memory publicInput
    ) internal view virtual;
}

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

import "IPeriodicColumn.sol";
import "MemoryMap.sol";
import "StarkParameters.sol";
import "CpuPublicInputOffsets.sol";
import "CairoVerifierContract.sol";

abstract contract LayoutSpecific is MemoryMap, StarkParameters, CpuPublicInputOffsets, CairoVerifierContract {
    IPeriodicColumn pedersenPointsX;
    IPeriodicColumn pedersenPointsY;
    IPeriodicColumn ecdsaPointsX;
    IPeriodicColumn ecdsaPointsY;

    function initPeriodicColumns(address[] memory auxPolynomials) internal {
        pedersenPointsX = IPeriodicColumn(auxPolynomials[1]);
        pedersenPointsY = IPeriodicColumn(auxPolynomials[2]);
        ecdsaPointsX = IPeriodicColumn(auxPolynomials[3]);
        ecdsaPointsY = IPeriodicColumn(auxPolynomials[4]);
    }

    function getLayoutInfo()
        external pure override returns (uint256 publicMemoryOffset, uint256 selectedBuiltins) {
        publicMemoryOffset = OFFSET_N_PUBLIC_MEMORY_PAGES;
        selectedBuiltins =
            (1 << OUTPUT_BUILTIN_BIT) |
            (1 << PEDERSEN_BUILTIN_BIT) |
            (1 << RANGE_CHECK_BUILTIN_BIT) |
            (1 << ECDSA_BUILTIN_BIT) |
            (1 << BITWISE_BUILTIN_BIT) |
            (1 << EC_OP_BUILTIN_BIT);
    }

    function safeDiv(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        require(denominator > 0, "The denominator must not be zero");
        require(numerator % denominator == 0, "The numerator is not divisible by the denominator.");
        return numerator / denominator;
    }

    function validateBuiltinPointers(
        uint256 initialAddress, uint256 stopAddress, uint256 builtinRatio, uint256 cellsPerInstance,
        uint256 nSteps, string memory builtinName)
        internal pure {
        require(
            initialAddress < 2**64,
            string(abi.encodePacked("Out of range ", builtinName, " begin_addr.")));
        uint256 maxStopPtr = initialAddress + cellsPerInstance * safeDiv(nSteps, builtinRatio);
        require(
            initialAddress <= stopAddress && stopAddress <= maxStopPtr,
            string(abi.encodePacked("Invalid ", builtinName, " stop_ptr.")));
    }

    function layoutSpecificInit(uint256[] memory ctx, uint256[] memory publicInput)
        internal pure {
        // "output" memory segment.
        uint256 outputBeginAddr = publicInput[OFFSET_OUTPUT_BEGIN_ADDR];
        uint256 outputStopPtr = publicInput[OFFSET_OUTPUT_STOP_PTR];
        require(outputBeginAddr <= outputStopPtr, "output begin_addr must be <= stop_ptr");
        require(outputStopPtr < 2**64, "Out of range output stop_ptr.");

        uint256 nSteps = 2 ** ctx[MM_LOG_N_STEPS];

        // "pedersen" memory segment.
        ctx[MM_INITIAL_PEDERSEN_ADDR] = publicInput[OFFSET_PEDERSEN_BEGIN_ADDR];
        validateBuiltinPointers(
            ctx[MM_INITIAL_PEDERSEN_ADDR], publicInput[OFFSET_PEDERSEN_STOP_PTR],
            PEDERSEN_BUILTIN_RATIO, 3, nSteps, 'pedersen');

        // Pedersen's shiftPoint values.
        ctx[MM_PEDERSEN__SHIFT_POINT_X] =
            0x49ee3eba8c1600700ee1b87eb599f16716b0b1022947733551fde4050ca6804;
        ctx[MM_PEDERSEN__SHIFT_POINT_Y] =
            0x3ca0cfe4b3bc6ddf346d49d06ea0ed34e621062c0e056c1d0405d266e10268a;

        // "range_check" memory segment.
        ctx[MM_INITIAL_RC_ADDR] = publicInput[OFFSET_RANGE_CHECK_BEGIN_ADDR];
        validateBuiltinPointers(
            ctx[MM_INITIAL_RC_ADDR], publicInput[OFFSET_RANGE_CHECK_STOP_PTR],
            RC_BUILTIN_RATIO, 1, nSteps, 'range_check');
        ctx[MM_RC16__PERM__PUBLIC_MEMORY_PROD] = 1;

        // "ecdsa" memory segment.
        ctx[MM_INITIAL_ECDSA_ADDR] = publicInput[OFFSET_ECDSA_BEGIN_ADDR];
        validateBuiltinPointers(
            ctx[MM_INITIAL_ECDSA_ADDR], publicInput[OFFSET_ECDSA_STOP_PTR],
            ECDSA_BUILTIN_RATIO, 2, nSteps, 'ecdsa');

        ctx[MM_ECDSA__SIG_CONFIG_ALPHA] = 1;
        ctx[MM_ECDSA__SIG_CONFIG_BETA] =
            0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;
        ctx[MM_ECDSA__SIG_CONFIG_SHIFT_POINT_X] =
            0x49ee3eba8c1600700ee1b87eb599f16716b0b1022947733551fde4050ca6804;
        ctx[MM_ECDSA__SIG_CONFIG_SHIFT_POINT_Y] =
            0x3ca0cfe4b3bc6ddf346d49d06ea0ed34e621062c0e056c1d0405d266e10268a;

        // "bitwise" memory segment.
        ctx[MM_INITIAL_BITWISE_ADDR] = publicInput[OFFSET_BITWISE_BEGIN_ADDR];
        validateBuiltinPointers(
            ctx[MM_INITIAL_BITWISE_ADDR], publicInput[OFFSET_BITWISE_STOP_ADDR],
            BITWISE__RATIO, 5, nSteps, 'bitwise');

        ctx[MM_DILUTED_CHECK__PERMUTATION__PUBLIC_MEMORY_PROD] = 1;
        ctx[MM_DILUTED_CHECK__FIRST_ELM] = 0;

        // "ec_op" memory segment.
        ctx[MM_INITIAL_EC_OP_ADDR] = publicInput[OFFSET_EC_OP_BEGIN_ADDR];
        validateBuiltinPointers(
            ctx[MM_INITIAL_EC_OP_ADDR], publicInput[OFFSET_EC_OP_STOP_ADDR],
            EC_OP_BUILTIN_RATIO, 7, nSteps, 'ec_op');

        ctx[MM_EC_OP__CURVE_CONFIG_ALPHA] = 1;
    }

    function prepareForOodsCheck(uint256[] memory ctx) internal view {
        uint256 oodsPoint = ctx[MM_OODS_POINT];
        uint256 nSteps = 2 ** ctx[MM_LOG_N_STEPS];

        // The number of copies in the pedersen hash periodic columns is
        // nSteps / PEDERSEN_BUILTIN_RATIO / PEDERSEN_BUILTIN_REPETITIONS.
        uint256 nPedersenHashCopies = safeDiv(
            nSteps,
            PEDERSEN_BUILTIN_RATIO * PEDERSEN_BUILTIN_REPETITIONS);
        uint256 zPointPowPedersen = fpow(oodsPoint, nPedersenHashCopies);
        ctx[MM_PERIODIC_COLUMN__PEDERSEN__POINTS__X] = pedersenPointsX.compute(zPointPowPedersen);
        ctx[MM_PERIODIC_COLUMN__PEDERSEN__POINTS__Y] = pedersenPointsY.compute(zPointPowPedersen);

        // The number of copies in the ECDSA signature periodic columns is
        // nSteps / ECDSA_BUILTIN_RATIO / ECDSA_BUILTIN_REPETITIONS.
        uint256 nEcdsaSignatureCopies = safeDiv(
            2 ** ctx[MM_LOG_N_STEPS],
            ECDSA_BUILTIN_RATIO * ECDSA_BUILTIN_REPETITIONS);
        uint256 zPointPowEcdsa = fpow(oodsPoint, nEcdsaSignatureCopies);

        ctx[MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__X] = ecdsaPointsX.compute(zPointPowEcdsa);
        ctx[MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__Y] = ecdsaPointsY.compute(zPointPowEcdsa);

        ctx[MM_DILUTED_CHECK__PERMUTATION__INTERACTION_ELM] = ctx[MM_INTERACTION_ELEMENTS +
            3];
        ctx[MM_DILUTED_CHECK__INTERACTION_Z] = ctx[MM_INTERACTION_ELEMENTS + 4];
        ctx[MM_DILUTED_CHECK__INTERACTION_ALPHA] = ctx[MM_INTERACTION_ELEMENTS +
            5];

        ctx[MM_DILUTED_CHECK__FINAL_CUM_VAL] = computeDilutedCumulativeValue(ctx);
    }

    /*
      Computes the final cumulative value of the diluted pool.
    */
    function computeDilutedCumulativeValue(uint256[] memory ctx)
        internal
        pure
        returns (uint256 res)
    {
        // The cumulative value is defined using the following recursive formula:
        //   r_1 = 1, r_{j+1} = r_j * (1 + z * u_j) + alpha * u_j^2 (for j >= 1)
        // where u_j = Dilute(j, spacing, n_bits) - Dilute(j-1, spacing, n_bits)
        // and we want to compute the final value r_{2^n_bits}.
        // Note that u_j depends only on the number of trailing zeros in the binary representation
        // of j. Specifically,
        //   u_{(1 + 2k) * 2^i} = u_{2^i} =
        //   u_{2^{i - 1}} + 2^{i * spacing} - 2^{(i - 1) * spacing + 1}.
        //
        // The recursive formula can be reduced to a nonrecursive form:
        //   r_j = prod_{n=1..j-1}(1 + z*u_n) +
        //     alpha * sum_{n=1..j-1}(u_n^2 * prod_{m=n + 1..j - 1}(1 + z * u_m))
        //
        // We rewrite this equation to generate a recursive formula that converges in log(j) steps:
        // Denote:
        //   p_i = prod_{n=1..2^i - 1}(1 + z * u_n)
        //   q_i = sum_{n=1..2^i - 1}(u_n^2 * prod_{m=n + 1..2^i-1}(1 + z * u_m))
        //   x_i = u_{2^i}.
        //
        // Clearly
        //   r_{2^i} = p_i + alpha * q_i.
        // Moreover, due to the symmetry of the sequence u_j,
        //   p_i = p_{i - 1} * (1 + z * x_{i - 1}) * p_{i - 1}
        //   q_i = q_{i - 1} * (1 + z * x_{i - 1}) * p_{i - 1} + x_{i - 1}^2 * p_{i - 1} + q_{i - 1}
        //
        // Now we can compute p_{n_bits} and q_{n_bits} in 'n_bits' steps and we are done.
        uint256 z = ctx[MM_DILUTED_CHECK__INTERACTION_Z];
        uint256 alpha = ctx[MM_DILUTED_CHECK__INTERACTION_ALPHA];
        uint256 diffMultiplier = 1 << DILUTED_SPACING;
        uint256 diffX = diffMultiplier - 2;
        // Initialize p, q and x to p_1, q_1 and x_0 respectively.
        uint256 p = 1 + z;
        uint256 q = 1;
        uint256 x = 1;
        assembly {
            for {
                let i := 1
            } lt(i, DILUTED_N_BITS) {
                i := add(i, 1)
            } {
                x := addmod(x, diffX, K_MODULUS)
                diffX := mulmod(diffX, diffMultiplier, K_MODULUS)
                // To save multiplications, store intermediate values.
                let x_p := mulmod(x, p, K_MODULUS)
                let y := add(p, mulmod(z, x_p, K_MODULUS))
                q := addmod(
                add(mulmod(q, y, K_MODULUS), mulmod(x, x_p, K_MODULUS)),
                    q,
                    K_MODULUS
                )
                p := mulmod(p, y, K_MODULUS)
            }
            res := addmod(p, mulmod(q, alpha, K_MODULUS), K_MODULUS)
        }
    }
}
// ---------- End of auto-generated code. ----------

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MemoryMap.sol";

contract MemoryAccessUtils is MemoryMap {
    function getPtr(uint256[] memory ctx, uint256 offset) internal pure returns (uint256) {
        uint256 ctxPtr;
        require(offset < MM_CONTEXT_SIZE, "Overflow protection failed");
        assembly {
            ctxPtr := add(ctx, 0x20)
        }
        return ctxPtr + offset * 0x20;
    }

    function getProofPtr(uint256[] memory proof) internal pure returns (uint256) {
        uint256 proofPtr;
        assembly {
            proofPtr := proof
        }
        return proofPtr;
    }

    function getChannelPtr(uint256[] memory ctx) internal pure returns (uint256) {
        uint256 ctxPtr;
        assembly {
            ctxPtr := add(ctx, 0x20)
        }
        return ctxPtr + MM_CHANNEL * 0x20;
    }

    function getQueries(uint256[] memory ctx) internal pure returns (uint256[] memory) {
        uint256[] memory queries;
        // Dynamic array holds length followed by values.
        uint256 offset = 0x20 + 0x20 * MM_N_UNIQUE_QUERIES;
        assembly {
            queries := add(ctx, offset)
        }
        return queries;
    }

    function getMerkleQueuePtr(uint256[] memory ctx) internal pure returns (uint256) {
        return getPtr(ctx, MM_MERKLE_QUEUE);
    }

    function getFriStepSizes(uint256[] memory ctx)
        internal
        pure
        returns (uint256[] memory friStepSizes)
    {
        uint256 friStepSizesPtr = getPtr(ctx, MM_FRI_STEP_SIZES_PTR);
        assembly {
            friStepSizes := mload(friStepSizesPtr)
        }
    }
}

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

contract MemoryMap {
    /*
      We store the state of the verifier in a contiguous chunk of memory.
      The offsets of the different fields are listed below.
      E.g. The offset of the i'th hash is [mm_hashes + i].
    */
    uint256 constant internal MAX_N_QUERIES = 48;
    uint256 constant internal FRI_QUEUE_SIZE = MAX_N_QUERIES;

    uint256 constant internal MAX_FRI_STEPS = 10;
    uint256 constant internal MAX_SUPPORTED_FRI_STEP_SIZE = 4;

    uint256 constant internal MM_EVAL_DOMAIN_SIZE =                          0x0;
    uint256 constant internal MM_BLOW_UP_FACTOR =                            0x1;
    uint256 constant internal MM_LOG_EVAL_DOMAIN_SIZE =                      0x2;
    uint256 constant internal MM_PROOF_OF_WORK_BITS =                        0x3;
    uint256 constant internal MM_EVAL_DOMAIN_GENERATOR =                     0x4;
    uint256 constant internal MM_PUBLIC_INPUT_PTR =                          0x5;
    uint256 constant internal MM_TRACE_COMMITMENT =                          0x6; // uint256[2]
    uint256 constant internal MM_OODS_COMMITMENT =                           0x8;
    uint256 constant internal MM_N_UNIQUE_QUERIES =                          0x9;
    uint256 constant internal MM_CHANNEL =                                   0xa; // uint256[3]
    uint256 constant internal MM_MERKLE_QUEUE =                              0xd; // uint256[96]
    uint256 constant internal MM_FRI_QUEUE =                                0x6d; // uint256[144]
    uint256 constant internal MM_FRI_QUERIES_DELIMITER =                    0xfd;
    uint256 constant internal MM_FRI_CTX =                                  0xfe; // uint256[40]
    uint256 constant internal MM_FRI_STEP_SIZES_PTR =                      0x126;
    uint256 constant internal MM_FRI_EVAL_POINTS =                         0x127; // uint256[10]
    uint256 constant internal MM_FRI_COMMITMENTS =                         0x131; // uint256[10]
    uint256 constant internal MM_FRI_LAST_LAYER_DEG_BOUND =                0x13b;
    uint256 constant internal MM_FRI_LAST_LAYER_PTR =                      0x13c;
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_START =              0x13d;
    uint256 constant internal MM_PERIODIC_COLUMN__PEDERSEN__POINTS__X =    0x13d;
    uint256 constant internal MM_PERIODIC_COLUMN__PEDERSEN__POINTS__Y =    0x13e;
    uint256 constant internal MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__X = 0x13f;
    uint256 constant internal MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__Y = 0x140;
    uint256 constant internal MM_TRACE_LENGTH =                            0x141;
    uint256 constant internal MM_OFFSET_SIZE =                             0x142;
    uint256 constant internal MM_HALF_OFFSET_SIZE =                        0x143;
    uint256 constant internal MM_INITIAL_AP =                              0x144;
    uint256 constant internal MM_INITIAL_PC =                              0x145;
    uint256 constant internal MM_FINAL_AP =                                0x146;
    uint256 constant internal MM_FINAL_PC =                                0x147;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__PERM__INTERACTION_ELM = 0x148;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__HASH_INTERACTION_ELM0 = 0x149;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__PERM__PUBLIC_MEMORY_PROD = 0x14a;
    uint256 constant internal MM_RC16__PERM__INTERACTION_ELM =             0x14b;
    uint256 constant internal MM_RC16__PERM__PUBLIC_MEMORY_PROD =          0x14c;
    uint256 constant internal MM_RC_MIN =                                  0x14d;
    uint256 constant internal MM_RC_MAX =                                  0x14e;
    uint256 constant internal MM_DILUTED_CHECK__PERMUTATION__INTERACTION_ELM = 0x14f;
    uint256 constant internal MM_DILUTED_CHECK__PERMUTATION__PUBLIC_MEMORY_PROD = 0x150;
    uint256 constant internal MM_DILUTED_CHECK__FIRST_ELM =                0x151;
    uint256 constant internal MM_DILUTED_CHECK__INTERACTION_Z =            0x152;
    uint256 constant internal MM_DILUTED_CHECK__INTERACTION_ALPHA =        0x153;
    uint256 constant internal MM_DILUTED_CHECK__FINAL_CUM_VAL =            0x154;
    uint256 constant internal MM_PEDERSEN__SHIFT_POINT_X =                 0x155;
    uint256 constant internal MM_PEDERSEN__SHIFT_POINT_Y =                 0x156;
    uint256 constant internal MM_INITIAL_PEDERSEN_ADDR =                   0x157;
    uint256 constant internal MM_INITIAL_RC_ADDR =                         0x158;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_ALPHA =                 0x159;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_SHIFT_POINT_X =         0x15a;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_SHIFT_POINT_Y =         0x15b;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_BETA =                  0x15c;
    uint256 constant internal MM_INITIAL_ECDSA_ADDR =                      0x15d;
    uint256 constant internal MM_INITIAL_BITWISE_ADDR =                    0x15e;
    uint256 constant internal MM_INITIAL_EC_OP_ADDR =                      0x15f;
    uint256 constant internal MM_EC_OP__CURVE_CONFIG_ALPHA =               0x160;
    uint256 constant internal MM_TRACE_GENERATOR =                         0x161;
    uint256 constant internal MM_OODS_POINT =                              0x162;
    uint256 constant internal MM_INTERACTION_ELEMENTS =                    0x163; // uint256[6]
    uint256 constant internal MM_COEFFICIENTS =                            0x169; // uint256[230]
    uint256 constant internal MM_OODS_VALUES =                             0x24f; // uint256[286]
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_END =                0x36d;
    uint256 constant internal MM_COMPOSITION_OODS_VALUES =                 0x36d; // uint256[2]
    uint256 constant internal MM_OODS_EVAL_POINTS =                        0x36f; // uint256[48]
    uint256 constant internal MM_OODS_COEFFICIENTS =                       0x39f; // uint256[288]
    uint256 constant internal MM_TRACE_QUERY_RESPONSES =                   0x4bf; // uint256[1296]
    uint256 constant internal MM_COMPOSITION_QUERY_RESPONSES =             0x9cf; // uint256[96]
    uint256 constant internal MM_LOG_N_STEPS =                             0xa2f;
    uint256 constant internal MM_N_PUBLIC_MEM_ENTRIES =                    0xa30;
    uint256 constant internal MM_N_PUBLIC_MEM_PAGES =                      0xa31;
    uint256 constant internal MM_CONTEXT_SIZE =                            0xa32;
}
// ---------- End of auto-generated code. ----------

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "FactRegistry.sol";

contract MemoryPageFactRegistryConstants {
    // A page based on a list of pairs (address, value).
    // In this case, memoryHash = hash(address, value, address, value, address, value, ...).
    uint256 internal constant REGULAR_PAGE = 0;
    // A page based on adjacent memory cells, starting from a given address.
    // In this case, memoryHash = hash(value, value, value, ...).
    uint256 internal constant CONTINUOUS_PAGE = 1;
}

/*
  A fact registry for the claim:
    I know n pairs (addr, value) for which the hash of the pairs is memoryHash, and the cumulative
    product: \prod_i( z - (addr_i + alpha * value_i) ) is prod.
  The exact format of the hash depends on the type of the page
  (see MemoryPageFactRegistryConstants).
  The fact consists of (pageType, prime, n, z, alpha, prod, memoryHash, address).
  Note that address is only available for CONTINUOUS_PAGE, and otherwise it is 0.
*/
contract MemoryPageFactRegistry is FactRegistry, MemoryPageFactRegistryConstants {
    event LogMemoryPageFactRegular(bytes32 factHash, uint256 memoryHash, uint256 prod);
    event LogMemoryPageFactContinuous(bytes32 factHash, uint256 memoryHash, uint256 prod);

    /*
      Registers a fact based of the given memory (address, value) pairs (REGULAR_PAGE).
    */
    function registerRegularMemoryPage(
        uint256[] calldata memoryPairs,
        uint256 z,
        uint256 alpha,
        uint256 prime
    )
        external
        returns (
            bytes32 factHash,
            uint256 memoryHash,
            uint256 prod
        )
    {
        require(memoryPairs.length < 2**20, "Too many memory values.");
        require(memoryPairs.length % 2 == 0, "Size of memoryPairs must be even.");
        require(z < prime, "Invalid value of z.");
        require(alpha < prime, "Invalid value of alpha.");
        (factHash, memoryHash, prod) = computeFactHash(memoryPairs, z, alpha, prime);
        emit LogMemoryPageFactRegular(factHash, memoryHash, prod);

        registerFact(factHash);
    }

    function computeFactHash(
        uint256[] memory memoryPairs,
        uint256 z,
        uint256 alpha,
        uint256 prime
    )
        private
        pure
        returns (
            bytes32 factHash,
            uint256 memoryHash,
            uint256 prod
        )
    {
        uint256 memorySize = memoryPairs.length / 2; // NOLINT: divide-before-multiply.

        prod = 1;

        assembly {
            let memoryPtr := add(memoryPairs, 0x20)

            // Each value of memoryPairs is a pair: (address, value).
            let lastPtr := add(memoryPtr, mul(memorySize, 0x40))
            for {
                let ptr := memoryPtr
            } lt(ptr, lastPtr) {
                ptr := add(ptr, 0x40)
            } {
                // Compute address + alpha * value.
                let address_value_lin_comb := addmod(
                    // address=
                    mload(ptr),
                    mulmod(
                        // value=
                        mload(add(ptr, 0x20)),
                        alpha,
                        prime
                    ),
                    prime
                )
                prod := mulmod(prod, add(z, sub(prime, address_value_lin_comb)), prime)
            }

            memoryHash := keccak256(
                memoryPtr,
                mul(
                    // 0x20 * 2.
                    0x40,
                    memorySize
                )
            )
        }

        factHash = keccak256(
            abi.encodePacked(
                REGULAR_PAGE,
                prime,
                memorySize,
                z,
                alpha,
                prod,
                memoryHash,
                uint256(0)
            )
        );
    }

    /*
      Registers a fact based on the given values, assuming continuous addresses.
      values should be [value at startAddr, value at (startAddr + 1), ...].
    */
    function registerContinuousMemoryPage(
        // NOLINT: external-function.
        uint256 startAddr,
        uint256[] memory values,
        uint256 z,
        uint256 alpha,
        uint256 prime
    )
        public
        returns (
            bytes32 factHash,
            uint256 memoryHash,
            uint256 prod
        )
    {
        require(values.length < 2**20, "Too many memory values.");
        require(prime < 2**254, "prime is too big for the optimizations in this function.");
        require(z < prime, "Invalid value of z.");
        require(alpha < prime, "Invalid value of alpha.");
        require(startAddr < 2**64 && startAddr < prime, "Invalid value of startAddr.");

        uint256 nValues = values.length;

        assembly {
            // Initialize prod to 1.
            prod := 1
            // Initialize valuesPtr to point to the first value in the array.
            let valuesPtr := add(values, 0x20)

            let minus_z := mod(sub(prime, z), prime)

            // Start by processing full batches of 8 cells, addr represents the last address in each
            // batch.
            let addr := add(startAddr, 7)
            let lastAddr := add(startAddr, nValues)
            for {

            } lt(addr, lastAddr) {
                addr := add(addr, 8)
            } {
                // Compute the product of (lin_comb - z) instead of (z - lin_comb), since we're
                // doing an even number of iterations, the result is the same.
                prod := mulmod(
                    prod,
                    mulmod(
                        add(add(sub(addr, 7), mulmod(mload(valuesPtr), alpha, prime)), minus_z),
                        add(
                            add(sub(addr, 6), mulmod(mload(add(valuesPtr, 0x20)), alpha, prime)),
                            minus_z
                        ),
                        prime
                    ),
                    prime
                )

                prod := mulmod(
                    prod,
                    mulmod(
                        add(
                            add(sub(addr, 5), mulmod(mload(add(valuesPtr, 0x40)), alpha, prime)),
                            minus_z
                        ),
                        add(
                            add(sub(addr, 4), mulmod(mload(add(valuesPtr, 0x60)), alpha, prime)),
                            minus_z
                        ),
                        prime
                    ),
                    prime
                )

                prod := mulmod(
                    prod,
                    mulmod(
                        add(
                            add(sub(addr, 3), mulmod(mload(add(valuesPtr, 0x80)), alpha, prime)),
                            minus_z
                        ),
                        add(
                            add(sub(addr, 2), mulmod(mload(add(valuesPtr, 0xa0)), alpha, prime)),
                            minus_z
                        ),
                        prime
                    ),
                    prime
                )

                prod := mulmod(
                    prod,
                    mulmod(
                        add(
                            add(sub(addr, 1), mulmod(mload(add(valuesPtr, 0xc0)), alpha, prime)),
                            minus_z
                        ),
                        add(add(addr, mulmod(mload(add(valuesPtr, 0xe0)), alpha, prime)), minus_z),
                        prime
                    ),
                    prime
                )

                valuesPtr := add(valuesPtr, 0x100)
            }

            // Handle leftover.
            // Translate addr to the beginning of the last incomplete batch.
            addr := sub(addr, 7)
            for {

            } lt(addr, lastAddr) {
                addr := add(addr, 1)
            } {
                let address_value_lin_comb := addmod(
                    addr,
                    mulmod(mload(valuesPtr), alpha, prime),
                    prime
                )
                prod := mulmod(prod, add(z, sub(prime, address_value_lin_comb)), prime)
                valuesPtr := add(valuesPtr, 0x20)
            }

            memoryHash := keccak256(add(values, 0x20), mul(0x20, nValues))
        }

        factHash = keccak256(
            abi.encodePacked(CONTINUOUS_PAGE, prime, nValues, z, alpha, prod, memoryHash, startAddr)
        );

        emit LogMemoryPageFactContinuous(factHash, memoryHash, prod);

        registerFact(factHash);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "FactRegistry.sol";
import "MerkleVerifier.sol";

contract MerkleStatementContract is MerkleVerifier, FactRegistry {
    /*
      This function receives an initial Merkle queue (consists of indices of leaves in the Merkle
      in addition to their values) and a Merkle view (contains the values of all the nodes
      required to be able to validate the queue). In case of success it registers the Merkle fact,
      which is the hash of the queue together with the resulting root.
    */
    // NOLINTNEXTLINE: external-function.
    function verifyMerkle(
        uint256[] memory merkleView,
        uint256[] memory initialMerkleQueue,
        uint256 height,
        uint256 expectedRoot
    ) public {
        // Ensure 'height' is bounded from above as a sanity check
        // (the bound is somewhat arbitrary).
        require(height < 200, "Height must be < 200.");
        require(
            initialMerkleQueue.length <= MAX_N_MERKLE_VERIFIER_QUERIES * 2,
            "TOO_MANY_MERKLE_QUERIES"
        );
        require(initialMerkleQueue.length % 2 == 0, "ODD_MERKLE_QUEUE_SIZE");

        uint256 merkleQueuePtr;
        uint256 channelPtr;
        uint256 nQueries;
        uint256 dataToHashPtr;
        uint256 badInput = 0;

        assembly {
            // Skip 0x20 bytes length at the beginning of the merkleView.
            let merkleViewPtr := add(merkleView, 0x20)
            // Let channelPtr point to a free space.
            channelPtr := mload(0x40) // freePtr.
            // channelPtr will point to the merkleViewPtr since the 'verify' function expects
            // a pointer to the proofPtr.
            mstore(channelPtr, merkleViewPtr)
            // Skip 0x20 bytes length at the beginning of the initialMerkleQueue.
            merkleQueuePtr := add(initialMerkleQueue, 0x20)
            // Get number of queries.
            nQueries := div(mload(initialMerkleQueue), 0x2) //NOLINT: divide-before-multiply.
            // Get a pointer to the end of initialMerkleQueue.
            let initialMerkleQueueEndPtr := add(
                merkleQueuePtr,
                mul(nQueries, MERKLE_SLOT_SIZE_IN_BYTES)
            )
            // Let dataToHashPtr point to a free memory.
            dataToHashPtr := add(channelPtr, 0x20) // Next freePtr.

            // Copy initialMerkleQueue to dataToHashPtr and validaite the indices.
            // The indices need to be in the range [2**height..2*(height+1)-1] and
            // strictly incrementing.

            // First index needs to be >= 2**height.
            let idxLowerLimit := shl(height, 1)
            for {

            } lt(merkleQueuePtr, initialMerkleQueueEndPtr) {

            } {
                let curIdx := mload(merkleQueuePtr)
                // badInput |= curIdx < IdxLowerLimit.
                badInput := or(badInput, lt(curIdx, idxLowerLimit))

                // The next idx must be at least curIdx + 1.
                idxLowerLimit := add(curIdx, 1)

                // Copy the pair (idx, hash) to the dataToHash array.
                mstore(dataToHashPtr, curIdx)
                mstore(add(dataToHashPtr, 0x20), mload(add(merkleQueuePtr, 0x20)))

                dataToHashPtr := add(dataToHashPtr, 0x40)
                merkleQueuePtr := add(merkleQueuePtr, MERKLE_SLOT_SIZE_IN_BYTES)
            }

            // We need to enforce that lastIdx < 2**(height+1)
            // => fail if lastIdx >= 2**(height+1)
            // => fail if (lastIdx + 1) > 2**(height+1)
            // => fail if idxLowerLimit > 2**(height+1).
            badInput := or(badInput, gt(idxLowerLimit, shl(height, 2)))

            // Reset merkleQueuePtr.
            merkleQueuePtr := add(initialMerkleQueue, 0x20)
            // Let freePtr point to a free memory (one word after the copied queries - reserved
            // for the root).
            mstore(0x40, add(dataToHashPtr, 0x20))
        }
        require(badInput == 0, "INVALID_MERKLE_INDICES");
        bytes32 resRoot = verifyMerkle(channelPtr, merkleQueuePtr, bytes32(expectedRoot), nQueries);
        bytes32 factHash;
        assembly {
            // Append the resulted root (should be the return value of verify) to dataToHashPtr.
            mstore(dataToHashPtr, resRoot)
            // Reset dataToHashPtr.
            dataToHashPtr := add(channelPtr, 0x20)
            factHash := keccak256(dataToHashPtr, add(mul(nQueries, 0x40), 0x20))
        }

        registerFact(factHash);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MerkleStatementContract.sol";

abstract contract MerkleStatementVerifier is IMerkleVerifier {
    MerkleStatementContract merkleStatementContract;

    constructor(address merkleStatementContractAddress) public {
        merkleStatementContract = MerkleStatementContract(merkleStatementContractAddress);
    }

    // Computes the hash of the Merkle statement, and verifies that it is registered in the
    // Merkle Fact Registry. Receives as input the queuePtr (as address), its length
    // the numbers of queries n, and the root. The channelPtr is is ignored.
    function verifyMerkle(
        uint256, /*channelPtr*/
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view virtual override returns (bytes32) {
        bytes32 statement;
        require(n <= MAX_N_MERKLE_VERIFIER_QUERIES, "TOO_MANY_MERKLE_QUERIES");

        assembly {
            let dataToHashPtrStart := mload(0x40) // freePtr.
            let dataToHashPtrCur := dataToHashPtrStart

            let queEndPtr := add(queuePtr, mul(n, 0x40))

            for {

            } lt(queuePtr, queEndPtr) {

            } {
                mstore(dataToHashPtrCur, mload(queuePtr))
                dataToHashPtrCur := add(dataToHashPtrCur, 0x20)
                queuePtr := add(queuePtr, 0x20)
            }

            mstore(dataToHashPtrCur, root)
            dataToHashPtrCur := add(dataToHashPtrCur, 0x20)
            mstore(0x40, dataToHashPtrCur)

            statement := keccak256(dataToHashPtrStart, sub(dataToHashPtrCur, dataToHashPtrStart))
        }
        require(merkleStatementContract.isValid(statement), "INVALIDATED_MERKLE_STATEMENT");
        return root;
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IMerkleVerifier.sol";

contract MerkleVerifier is IMerkleVerifier {
    // Commitments are masked to 160bit using the following mask to save gas costs.
    uint256 internal constant COMMITMENT_MASK = (
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
    );

    // The size of a commitment. We use 32 bytes (rather than 20 bytes) per commitment as it
    // simplifies the code.
    uint256 internal constant COMMITMENT_SIZE_IN_BYTES = 0x20;

    // The size of two commitments.
    uint256 internal constant TWO_COMMITMENTS_SIZE_IN_BYTES = 0x40;

    // The size of and index in the verifyMerkle queue.
    uint256 internal constant INDEX_SIZE_IN_BYTES = 0x20;

    /*
      Verifies a Merkle tree decommitment for n leaves in a Merkle tree with N leaves.

      The inputs data sits in the queue at queuePtr.
      Each slot in the queue contains a 32 bytes leaf index and a 32 byte leaf value.
      The indices need to be in the range [N..2*N-1] and strictly incrementing.
      Decommitments are read from the channel in the ctx.

      The input data is destroyed during verification.
    */
    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view virtual override returns (bytes32 hash) {
        require(n <= MAX_N_MERKLE_VERIFIER_QUERIES, "TOO_MANY_MERKLE_QUERIES");

        assembly {
            // queuePtr + i * MERKLE_SLOT_SIZE_IN_BYTES gives the i'th index in the queue.
            // hashesPtr + i * MERKLE_SLOT_SIZE_IN_BYTES gives the i'th hash in the queue.
            let hashesPtr := add(queuePtr, INDEX_SIZE_IN_BYTES)
            let queueSize := mul(n, MERKLE_SLOT_SIZE_IN_BYTES)

            // The items are in slots [0, n-1].
            let rdIdx := 0
            let wrIdx := 0 // = n % n.

            // Iterate the queue until we hit the root.
            let index := mload(add(rdIdx, queuePtr))
            let proofPtr := mload(channelPtr)

            // while(index > 1).
            for {

            } gt(index, 1) {

            } {
                let siblingIndex := xor(index, 1)
                // sibblingOffset := COMMITMENT_SIZE_IN_BYTES * lsb(siblingIndex).
                let sibblingOffset := mulmod(
                    siblingIndex,
                    COMMITMENT_SIZE_IN_BYTES,
                    TWO_COMMITMENTS_SIZE_IN_BYTES
                )

                // Store the hash corresponding to index in the correct slot.
                // 0 if index is even and 0x20 if index is odd.
                // The hash of the sibling will be written to the other slot.
                mstore(xor(0x20, sibblingOffset), mload(add(rdIdx, hashesPtr)))
                rdIdx := addmod(rdIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)

                // Inline channel operation:
                // Assume we are going to read a new hash from the proof.
                // If this is not the case add(proofPtr, COMMITMENT_SIZE_IN_BYTES) will be reverted.
                let newHashPtr := proofPtr
                proofPtr := add(proofPtr, COMMITMENT_SIZE_IN_BYTES)

                // Push index/2 into the queue, before reading the next index.
                // The order is important, as otherwise we may try to read from an empty queue (in
                // the case where we are working on one item).
                // wrIdx will be updated after writing the relevant hash to the queue.
                mstore(add(wrIdx, queuePtr), div(index, 2))

                // Load the next index from the queue and check if it is our sibling.
                index := mload(add(rdIdx, queuePtr))
                if eq(index, siblingIndex) {
                    // Take sibling from queue rather than from proof.
                    newHashPtr := add(rdIdx, hashesPtr)
                    // Revert reading from proof.
                    proofPtr := sub(proofPtr, COMMITMENT_SIZE_IN_BYTES)
                    rdIdx := addmod(rdIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)

                    // Index was consumed, read the next one.
                    // Note that the queue can't be empty at this point.
                    // The index of the parent of the current node was already pushed into the
                    // queue, and the parent is never the sibling.
                    index := mload(add(rdIdx, queuePtr))
                }

                mstore(sibblingOffset, mload(newHashPtr))

                // Push the new hash to the end of the queue.
                mstore(
                    add(wrIdx, hashesPtr),
                    and(COMMITMENT_MASK, keccak256(0x00, TWO_COMMITMENTS_SIZE_IN_BYTES))
                )
                wrIdx := addmod(wrIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)
            }
            hash := mload(add(rdIdx, hashesPtr))

            // Update the proof pointer in the context.
            mstore(channelPtr, proofPtr)
        }
        require(hash == root, "INVALID_MERKLE_PROOF");
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

contract PageInfo {
    uint256 public constant PAGE_INFO_SIZE = 3;
    // PAGE_INFO_SIZE_IN_BYTES cannot reference PAGE_INFO_SIZE as only direct constants are
    // supported in assembly.
    uint256 public constant PAGE_INFO_SIZE_IN_BYTES = 3 * 32;

    uint256 public constant PAGE_INFO_ADDRESS_OFFSET = 0;
    uint256 public constant PAGE_INFO_SIZE_OFFSET = 1;
    uint256 public constant PAGE_INFO_HASH_OFFSET = 2;

    // A regular page entry is a (address, value) pair stored as 2 uint256 words.
    uint256 internal constant MEMORY_PAIR_SIZE = 2;
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

contract PrimeFieldElement0 {
    uint256 internal constant K_MODULUS =
        0x800000000000011000000000000000000000000000000000000000000000001;
    uint256 internal constant K_MONTGOMERY_R =
        0x7fffffffffffdf0ffffffffffffffffffffffffffffffffffffffffffffffe1;
    uint256 internal constant K_MONTGOMERY_R_INV =
        0x40000000000001100000000000012100000000000000000000000000000000;
    uint256 internal constant GENERATOR_VAL = 3;
    uint256 internal constant ONE_VAL = 1;

    function fromMontgomery(uint256 val) internal pure returns (uint256 res) {
        // uint256 res = fmul(val, kMontgomeryRInv);
        assembly {
            res := mulmod(val, K_MONTGOMERY_R_INV, K_MODULUS)
        }
        return res;
    }

    function fromMontgomeryBytes(bytes32 bs) internal pure returns (uint256) {
        // Assuming bs is a 256bit bytes object, in Montgomery form, it is read into a field
        // element.
        uint256 res = uint256(bs);
        return fromMontgomery(res);
    }

    function toMontgomeryInt(uint256 val) internal pure returns (uint256 res) {
        //uint256 res = fmul(val, kMontgomeryR);
        assembly {
            res := mulmod(val, K_MONTGOMERY_R, K_MODULUS)
        }
        return res;
    }

    function fmul(uint256 a, uint256 b) internal pure returns (uint256 res) {
        //uint256 res = mulmod(a, b, kModulus);
        assembly {
            res := mulmod(a, b, K_MODULUS)
        }
        return res;
    }

    function fadd(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, b, kModulus);
        assembly {
            res := addmod(a, b, K_MODULUS)
        }
        return res;
    }

    function fsub(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, kModulus - b, kModulus);
        assembly {
            res := addmod(a, sub(K_MODULUS, b), K_MODULUS)
        }
        return res;
    }

    function fpow(uint256 val, uint256 exp) internal view returns (uint256) {
        return expmod(val, exp, K_MODULUS);
    }

    function expmod(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) private view returns (uint256 res) {
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20) // Length of Base.
            mstore(add(p, 0x20), 0x20) // Length of Exponent.
            mstore(add(p, 0x40), 0x20) // Length of Modulus.
            mstore(add(p, 0x60), base) // Base.
            mstore(add(p, 0x80), exponent) // Exponent.
            mstore(add(p, 0xa0), modulus) // Modulus.
            // Call modexp precompile.
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            res := mload(p)
        }
    }

    function inverse(uint256 val) internal view returns (uint256) {
        return expmod(val, K_MODULUS - 2, K_MODULUS);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "PrimeFieldElement0.sol";

contract Prng is PrimeFieldElement0 {
    function storePrng(
        uint256 prngPtr,
        bytes32 digest,
        uint256 counter
    ) internal pure {
        assembly {
            mstore(prngPtr, digest)
            mstore(add(prngPtr, 0x20), counter)
        }
    }

    function loadPrng(uint256 prngPtr) internal pure returns (bytes32, uint256) {
        bytes32 digest;
        uint256 counter;

        assembly {
            digest := mload(prngPtr)
            counter := mload(add(prngPtr, 0x20))
        }

        return (digest, counter);
    }

    function initPrng(uint256 prngPtr, bytes32 publicInputHash) internal pure {
        storePrng(
            prngPtr,
            // keccak256(publicInput)
            publicInputHash,
            0
        );
    }

    /*
      Auxiliary function for getRandomBytes.
    */
    function getRandomBytesInner(bytes32 digest, uint256 counter)
        private
        pure
        returns (
            bytes32,
            uint256,
            bytes32
        )
    {
        // returns 32 bytes (for random field elements or four queries at a time).
        bytes32 randomBytes = keccak256(abi.encodePacked(digest, counter));

        return (digest, counter + 1, randomBytes);
    }

    /*
      Returns 32 bytes. Used for a random field element, or for 4 query indices.
    */
    function getRandomBytes(uint256 prngPtr) internal pure returns (bytes32 randomBytes) {
        bytes32 digest;
        uint256 counter;
        (digest, counter) = loadPrng(prngPtr);

        // returns 32 bytes (for random field elements or four queries at a time).
        (digest, counter, randomBytes) = getRandomBytesInner(digest, counter);

        storePrng(prngPtr, digest, counter);
        return randomBytes;
    }
}

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

import "PrimeFieldElement0.sol";

contract StarkParameters is PrimeFieldElement0 {
    uint256 constant internal N_COEFFICIENTS = 230;
    uint256 constant internal N_INTERACTION_ELEMENTS = 6;
    uint256 constant internal MASK_SIZE = 286;
    uint256 constant internal N_ROWS_IN_MASK = 146;
    uint256 constant internal N_COLUMNS_IN_MASK = 27;
    uint256 constant internal N_COLUMNS_IN_TRACE0 = 24;
    uint256 constant internal N_COLUMNS_IN_TRACE1 = 3;
    uint256 constant internal CONSTRAINTS_DEGREE_BOUND = 2;
    uint256 constant internal N_OODS_VALUES = MASK_SIZE + CONSTRAINTS_DEGREE_BOUND;
    uint256 constant internal N_OODS_COEFFICIENTS = N_OODS_VALUES;

    // ---------- // Air specific constants. ----------
    uint256 constant internal PUBLIC_MEMORY_STEP = 16;
    uint256 constant internal DILUTED_SPACING = 4;
    uint256 constant internal DILUTED_N_BITS = 16;
    uint256 constant internal PEDERSEN_BUILTIN_RATIO = 8;
    uint256 constant internal PEDERSEN_BUILTIN_REPETITIONS = 4;
    uint256 constant internal RC_BUILTIN_RATIO = 8;
    uint256 constant internal RC_N_PARTS = 8;
    uint256 constant internal ECDSA_BUILTIN_RATIO = 512;
    uint256 constant internal ECDSA_BUILTIN_REPETITIONS = 1;
    uint256 constant internal BITWISE__RATIO = 256;
    uint256 constant internal EC_OP_BUILTIN_RATIO = 256;
    uint256 constant internal EC_OP_SCALAR_HEIGHT = 256;
    uint256 constant internal EC_OP_N_BITS = 252;
    uint256 constant internal LAYOUT_CODE = 6384748;
    uint256 constant internal LOG_CPU_COMPONENT_HEIGHT = 4;
}
// ---------- End of auto-generated code. ----------

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Fri.sol";
import "MemoryMap.sol";
import "MemoryAccessUtils.sol";
import "IStarkVerifier.sol";
import "VerifierChannel.sol";

abstract contract StarkVerifier is
    MemoryMap,
    MemoryAccessUtils,
    VerifierChannel,
    IStarkVerifier,
    Fri
{
    /*
      The work required to generate an invalid proof is 2^numSecurityBits.
      Typical values: 80-128.
    */
    uint256 immutable numSecurityBits;

    /*
      The secuirty of a proof is a composition of bits obtained by PoW and bits obtained by FRI
      queries. The verifier requires at least minProofOfWorkBits to be obtained by PoW.
      Typical values: 20-30.
    */
    uint256 immutable minProofOfWorkBits;
    address oodsContractAddress;

    constructor(
        uint256 numSecurityBits_,
        uint256 minProofOfWorkBits_,
        address oodsContractAddress_
    ) public {
        numSecurityBits = numSecurityBits_;
        minProofOfWorkBits = minProofOfWorkBits_;
        oodsContractAddress = oodsContractAddress_;
    }

    /*
      To print LogDebug messages from assembly use code like the following:

      assembly {
            let val := 0x1234
            mstore(0, val) // uint256 val
            // log to the LogDebug(uint256) topic
            log1(0, 0x20, 0x2feb477e5c8c82cfb95c787ed434e820b1a28fa84d68bbf5aba5367382f5581c)
      }

      Note that you can't use log in a contract that was called with staticcall
      (ContraintPoly, Oods,...)

      If logging is needed replace the staticcall to call and add a third argument of 0.
    */
    event LogBool(bool val);
    event LogDebug(uint256 val);

    function airSpecificInit(uint256[] memory publicInput)
        internal
        view
        virtual
        returns (uint256[] memory ctx, uint256 logTraceLength);

    uint256 internal constant PROOF_PARAMS_N_QUERIES_OFFSET = 0;
    uint256 internal constant PROOF_PARAMS_LOG_BLOWUP_FACTOR_OFFSET = 1;
    uint256 internal constant PROOF_PARAMS_PROOF_OF_WORK_BITS_OFFSET = 2;
    uint256 internal constant PROOF_PARAMS_FRI_LAST_LAYER_LOG_DEG_BOUND_OFFSET = 3;
    uint256 internal constant PROOF_PARAMS_N_FRI_STEPS_OFFSET = 4;
    uint256 internal constant PROOF_PARAMS_FRI_STEPS_OFFSET = 5;

    function validateFriParams(
        uint256[] memory friStepSizes,
        uint256 logTraceLength,
        uint256 logFriLastLayerDegBound
    ) internal pure {
        require(friStepSizes[0] == 0, "Only eta0 == 0 is currently supported");

        uint256 expectedLogDegBound = logFriLastLayerDegBound;
        uint256 nFriSteps = friStepSizes.length;
        for (uint256 i = 1; i < nFriSteps; i++) {
            uint256 friStepSize = friStepSizes[i];
            require(friStepSize >= FRI_MIN_STEP_SIZE, "Min supported fri step size is 2.");
            require(friStepSize <= FRI_MAX_STEP_SIZE, "Max supported fri step size is 4.");
            expectedLogDegBound += friStepSize;
        }

        // FRI starts with a polynomial of degree 'traceLength'.
        // After applying all the FRI steps we expect to get a polynomial of degree less
        // than friLastLayerDegBound.
        require(expectedLogDegBound == logTraceLength, "Fri params do not match trace length");
    }

    function initVerifierParams(uint256[] memory publicInput, uint256[] memory proofParams)
        internal
        view
        returns (uint256[] memory ctx)
    {
        require(proofParams.length > PROOF_PARAMS_FRI_STEPS_OFFSET, "Invalid proofParams.");
        require(
            proofParams.length ==
                (PROOF_PARAMS_FRI_STEPS_OFFSET + proofParams[PROOF_PARAMS_N_FRI_STEPS_OFFSET]),
            "Invalid proofParams."
        );
        uint256 logBlowupFactor = proofParams[PROOF_PARAMS_LOG_BLOWUP_FACTOR_OFFSET];
        // Ensure 'logBlowupFactor' is bounded from above as a sanity check
        // (the bound is somewhat arbitrary).
        require(logBlowupFactor <= 16, "logBlowupFactor must be at most 16");
        require(logBlowupFactor >= 1, "logBlowupFactor must be at least 1");

        uint256 proofOfWorkBits = proofParams[PROOF_PARAMS_PROOF_OF_WORK_BITS_OFFSET];
        // Ensure 'proofOfWorkBits' is bounded from above as a sanity check
        // (the bound is somewhat arbitrary).
        require(proofOfWorkBits <= 50, "proofOfWorkBits must be at most 50");
        require(proofOfWorkBits >= minProofOfWorkBits, "minimum proofOfWorkBits not satisfied");
        require(proofOfWorkBits < numSecurityBits, "Proofs may not be purely based on PoW.");

        uint256 logFriLastLayerDegBound = (
            proofParams[PROOF_PARAMS_FRI_LAST_LAYER_LOG_DEG_BOUND_OFFSET]
        );
        require(logFriLastLayerDegBound <= 10, "logFriLastLayerDegBound must be at most 10.");

        uint256 nFriSteps = proofParams[PROOF_PARAMS_N_FRI_STEPS_OFFSET];
        require(nFriSteps <= MAX_FRI_STEPS, "Too many fri steps.");
        require(nFriSteps > 1, "Not enough fri steps.");

        uint256[] memory friStepSizes = new uint256[](nFriSteps);
        for (uint256 i = 0; i < nFriSteps; i++) {
            friStepSizes[i] = proofParams[PROOF_PARAMS_FRI_STEPS_OFFSET + i];
        }

        uint256 logTraceLength;
        (ctx, logTraceLength) = airSpecificInit(publicInput);

        validateFriParams(friStepSizes, logTraceLength, logFriLastLayerDegBound);

        uint256 friStepSizesPtr = getPtr(ctx, MM_FRI_STEP_SIZES_PTR);
        assembly {
            mstore(friStepSizesPtr, friStepSizes)
        }
        ctx[MM_FRI_LAST_LAYER_DEG_BOUND] = 2**logFriLastLayerDegBound;
        ctx[MM_TRACE_LENGTH] = 2**logTraceLength;

        ctx[MM_BLOW_UP_FACTOR] = 2**logBlowupFactor;
        ctx[MM_PROOF_OF_WORK_BITS] = proofOfWorkBits;

        uint256 nQueries = proofParams[PROOF_PARAMS_N_QUERIES_OFFSET];
        require(nQueries > 0, "Number of queries must be at least one");
        require(nQueries <= MAX_N_QUERIES, "Too many queries.");
        require(
            nQueries * logBlowupFactor + proofOfWorkBits >= numSecurityBits,
            "Proof params do not satisfy security requirements."
        );

        ctx[MM_N_UNIQUE_QUERIES] = nQueries;

        // We start with logEvalDomainSize = logTraceSize and update it here.
        ctx[MM_LOG_EVAL_DOMAIN_SIZE] = logTraceLength + logBlowupFactor;
        ctx[MM_EVAL_DOMAIN_SIZE] = 2**ctx[MM_LOG_EVAL_DOMAIN_SIZE];

        // Compute the generators for the evaluation and trace domains.
        uint256 genEvalDomain = fpow(GENERATOR_VAL, (K_MODULUS - 1) / ctx[MM_EVAL_DOMAIN_SIZE]);
        ctx[MM_EVAL_DOMAIN_GENERATOR] = genEvalDomain;
        ctx[MM_TRACE_GENERATOR] = fpow(genEvalDomain, ctx[MM_BLOW_UP_FACTOR]);
    }

    function getPublicInputHash(uint256[] memory publicInput)
        internal
        pure
        virtual
        returns (bytes32);

    function oodsConsistencyCheck(uint256[] memory ctx) internal view virtual;

    function getNColumnsInTrace() internal pure virtual returns (uint256);

    function getNColumnsInComposition() internal pure virtual returns (uint256);

    function getMmCoefficients() internal pure virtual returns (uint256);

    function getMmOodsValues() internal pure virtual returns (uint256);

    function getMmOodsCoefficients() internal pure virtual returns (uint256);

    function getNCoefficients() internal pure virtual returns (uint256);

    function getNOodsValues() internal pure virtual returns (uint256);

    function getNOodsCoefficients() internal pure virtual returns (uint256);

    // Interaction functions.
    // If the AIR uses interaction, the following functions should be overridden.
    function getNColumnsInTrace0() internal pure virtual returns (uint256) {
        return getNColumnsInTrace();
    }

    function getNColumnsInTrace1() internal pure virtual returns (uint256) {
        return 0;
    }

    function getMmInteractionElements() internal pure virtual returns (uint256) {
        revert("AIR does not support interaction.");
    }

    function getNInteractionElements() internal pure virtual returns (uint256) {
        revert("AIR does not support interaction.");
    }

    function hasInteraction() internal pure returns (bool) {
        return getNColumnsInTrace1() > 0;
    }

    /*
      Adjusts the query indices and generates evaluation points for each query index.
      The operations above are independent but we can save gas by combining them as both
      operations require us to iterate the queries array.

      Indices adjustment:
          The query indices adjustment is needed because both the Merkle verification and FRI
          expect queries "full binary tree in array" indices.
          The adjustment is simply adding evalDomainSize to each query.
          Note that evalDomainSize == 2^(#FRI layers) == 2^(Merkle tree hight).

      evalPoints generation:
          for each query index "idx" we compute the corresponding evaluation point:
              g^(bitReverse(idx, log_evalDomainSize).
    */
    function adjustQueryIndicesAndPrepareEvalPoints(uint256[] memory ctx) internal view {
        uint256 nUniqueQueries = ctx[MM_N_UNIQUE_QUERIES];
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 friQueueEnd = friQueue + nUniqueQueries * FRI_QUEUE_SLOT_SIZE_IN_BYTES;
        uint256 evalPointsPtr = getPtr(ctx, MM_OODS_EVAL_POINTS);
        uint256 log_evalDomainSize = ctx[MM_LOG_EVAL_DOMAIN_SIZE];
        uint256 evalDomainSize = ctx[MM_EVAL_DOMAIN_SIZE];
        uint256 evalDomainGenerator = ctx[MM_EVAL_DOMAIN_GENERATOR];

        assembly {
            /*
              Returns the bit reversal of value assuming it has the given number of bits.
              numberOfBits must be <= 64.
            */
            function bitReverse(value, numberOfBits) -> res {
                // Bit reverse value by swapping 1 bit chunks then 2 bit chunks and so forth.
                // A swap can be done by masking the relevant chunks and shifting them to the
                // correct location.
                // However, to save some shift operations we shift only one of the chunks by twice
                // the chunk size, and perform a single right shift at the end.
                res := value
                // Swap 1 bit chunks.
                res := or(shl(2, and(res, 0x5555555555555555)), and(res, 0xaaaaaaaaaaaaaaaa))
                // Swap 2 bit chunks.
                res := or(shl(4, and(res, 0x6666666666666666)), and(res, 0x19999999999999998))
                // Swap 4 bit chunks.
                res := or(shl(8, and(res, 0x7878787878787878)), and(res, 0x78787878787878780))
                // Swap 8 bit chunks.
                res := or(shl(16, and(res, 0x7f807f807f807f80)), and(res, 0x7f807f807f807f8000))
                // Swap 16 bit chunks.
                res := or(shl(32, and(res, 0x7fff80007fff8000)), and(res, 0x7fff80007fff80000000))
                // Swap 32 bit chunks.
                res := or(
                    shl(64, and(res, 0x7fffffff80000000)),
                    and(res, 0x7fffffff8000000000000000)
                )
                // Shift right the result.
                // Note that we combine two right shifts here:
                // 1. On each swap above we skip a right shift and get a left shifted result.
                //    Consequently, we need to right shift the final result by
                //    1 + 2 + 4 + 8 + 16 + 32 = 63.
                // 2. The step above computes the bit-reverse of a 64-bit input. If the goal is to
                //    bit-reverse only numberOfBits then the result needs to be right shifted by
                //    64 - numberOfBits.
                res := shr(sub(127, numberOfBits), res)
            }

            function expmod(base, exponent, modulus) -> res {
                let p := mload(0x40)
                mstore(p, 0x20) // Length of Base.
                mstore(add(p, 0x20), 0x20) // Length of Exponent.
                mstore(add(p, 0x40), 0x20) // Length of Modulus.
                mstore(add(p, 0x60), base) // Base.
                mstore(add(p, 0x80), exponent) // Exponent.
                mstore(add(p, 0xa0), modulus) // Modulus.
                // Call modexp precompile.
                if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                    revert(0, 0)
                }
                res := mload(p)
            }

            for {

            } lt(friQueue, friQueueEnd) {
                friQueue := add(friQueue, FRI_QUEUE_SLOT_SIZE_IN_BYTES)
            } {
                let queryIdx := mload(friQueue)
                // Adjust queryIdx, see comment in function description.
                let adjustedQueryIdx := add(queryIdx, evalDomainSize)
                mstore(friQueue, adjustedQueryIdx)

                // Compute the evaluation point corresponding to the current queryIdx.
                mstore(
                    evalPointsPtr,
                    expmod(evalDomainGenerator, bitReverse(queryIdx, log_evalDomainSize), K_MODULUS)
                )
                evalPointsPtr := add(evalPointsPtr, 0x20)
            }
        }
    }

    /*
      Reads query responses for nColumns from the channel with the corresponding authentication
      paths. Verifies the consistency of the authentication paths with respect to the given
      merkleRoot, and stores the query values in proofDataPtr.

      nTotalColumns is the total number of columns represented in proofDataPtr (which should be
      an array of nUniqueQueries rows of size nTotalColumns). nColumns is the number of columns
      for which data will be read by this function.
      The change to the proofDataPtr array will be as follows:
      * The first nColumns cells will be set,
      * The next nTotalColumns - nColumns will be skipped,
      * The next nColumns cells will be set,
      * The next nTotalColumns - nColumns will be skipped,
      * ...

      To set the last columns for each query simply add an offset to proofDataPtr before calling the
      function.
    */
    function readQueryResponsesAndDecommit(
        uint256[] memory ctx,
        uint256 nTotalColumns,
        uint256 nColumns,
        uint256 proofDataPtr,
        bytes32 merkleRoot
    ) internal view {
        require(nColumns <= getNColumnsInTrace() + getNColumnsInComposition(), "Too many columns.");

        uint256 nUniqueQueries = ctx[MM_N_UNIQUE_QUERIES];
        uint256 channelPtr = getPtr(ctx, MM_CHANNEL);
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 friQueueEnd = friQueue + nUniqueQueries * FRI_QUEUE_SLOT_SIZE_IN_BYTES;
        uint256 merkleQueuePtr = getPtr(ctx, MM_MERKLE_QUEUE);
        uint256 rowSize = 0x20 * nColumns;
        uint256 proofDataSkipBytes = 0x20 * (nTotalColumns - nColumns);

        assembly {
            let proofPtr := mload(channelPtr)
            let merklePtr := merkleQueuePtr

            for {

            } lt(friQueue, friQueueEnd) {
                friQueue := add(friQueue, FRI_QUEUE_SLOT_SIZE_IN_BYTES)
            } {
                let merkleLeaf := and(keccak256(proofPtr, rowSize), COMMITMENT_MASK)
                if eq(rowSize, 0x20) {
                    // If a leaf contains only 1 field element we don't hash it.
                    merkleLeaf := mload(proofPtr)
                }

                // push(queryIdx, hash(row)) to merkleQueue.
                mstore(merklePtr, mload(friQueue))
                mstore(add(merklePtr, 0x20), merkleLeaf)
                merklePtr := add(merklePtr, 0x40)

                // Copy query responses to proofData array.
                // This array will be sent to the OODS contract.
                for {
                    let proofDataChunk_end := add(proofPtr, rowSize)
                } lt(proofPtr, proofDataChunk_end) {
                    proofPtr := add(proofPtr, 0x20)
                } {
                    mstore(proofDataPtr, mload(proofPtr))
                    proofDataPtr := add(proofDataPtr, 0x20)
                }
                proofDataPtr := add(proofDataPtr, proofDataSkipBytes)
            }

            mstore(channelPtr, proofPtr)
        }

        verifyMerkle(channelPtr, merkleQueuePtr, merkleRoot, nUniqueQueries);
    }

    /*
      Computes the first FRI layer by reading the query responses and calling
      the OODS contract.

      The OODS contract will build and sum boundary constraints that check that
      the prover provided the proper evaluations for the Out of Domain Sampling.

      I.e. if the prover said that f(z) = c, the first FRI layer will include
      the term (f(x) - c)/(x-z).
    */
    function computeFirstFriLayer(uint256[] memory ctx) internal view {
        adjustQueryIndicesAndPrepareEvalPoints(ctx);
        readQueryResponsesAndDecommit(
            ctx,
            getNColumnsInTrace(),
            getNColumnsInTrace0(),
            getPtr(ctx, MM_TRACE_QUERY_RESPONSES),
            bytes32(ctx[MM_TRACE_COMMITMENT])
        );
        if (hasInteraction()) {
            readQueryResponsesAndDecommit(
                ctx,
                getNColumnsInTrace(),
                getNColumnsInTrace1(),
                getPtr(ctx, MM_TRACE_QUERY_RESPONSES + getNColumnsInTrace0()),
                bytes32(ctx[MM_TRACE_COMMITMENT + 1])
            );
        }

        readQueryResponsesAndDecommit(
            ctx,
            getNColumnsInComposition(),
            getNColumnsInComposition(),
            getPtr(ctx, MM_COMPOSITION_QUERY_RESPONSES),
            bytes32(ctx[MM_OODS_COMMITMENT])
        );

        address oodsAddress = oodsContractAddress;
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 returnDataSize = MAX_N_QUERIES * FRI_QUEUE_SLOT_SIZE_IN_BYTES;
        assembly {
            // Call the OODS contract.
            if iszero(
                staticcall(
                    not(0),
                    oodsAddress,
                    ctx,
                    mul(add(mload(ctx), 1), 0x20), /*sizeof(ctx)*/
                    friQueue,
                    returnDataSize
                )
            ) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /*
      Reads the last FRI layer (i.e. the polynomial's coefficients) from the channel.
      This differs from standard reading of channel field elements in several ways:
      -- The digest is updated by hashing it once with all coefficients simultaneously, rather than
         iteratively one by one.
      -- The coefficients are kept in Montgomery form, as is the case throughout the FRI
         computation.
      -- The coefficients are not actually read and copied elsewhere, but rather only a pointer to
         their location in the channel is stored.
    */
    function readLastFriLayer(uint256[] memory ctx) internal pure {
        uint256 lmmChannel = MM_CHANNEL;
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 lastLayerPtr;
        uint256 badInput = 0;

        assembly {
            let primeMinusOne := 0x800000000000011000000000000000000000000000000000000000000000000
            let channelPtr := add(add(ctx, 0x20), mul(lmmChannel, 0x20))
            lastLayerPtr := mload(channelPtr)

            // Make sure all the values are valid field elements.
            let length := mul(friLastLayerDegBound, 0x20)
            let lastLayerEnd := add(lastLayerPtr, length)
            for {
                let coefsPtr := lastLayerPtr
            } lt(coefsPtr, lastLayerEnd) {
                coefsPtr := add(coefsPtr, 0x20)
            } {
                badInput := or(badInput, gt(mload(coefsPtr), primeMinusOne))
            }

            // Update prng.digest with the hash of digest + 1 and the last layer coefficient.
            // (digest + 1) is written to the proof area because keccak256 needs all data to be
            // consecutive.
            let newDigestPtr := sub(lastLayerPtr, 0x20)
            let digestPtr := add(channelPtr, 0x20)
            // Overwriting the proof to minimize copying of data.
            mstore(newDigestPtr, add(mload(digestPtr), 1))

            // prng.digest := keccak256((digest+1)||lastLayerCoefs).
            mstore(digestPtr, keccak256(newDigestPtr, add(length, 0x20)))
            // prng.counter := 0.
            mstore(add(channelPtr, 0x40), 0)

            // Note: proof pointer is not incremented until this point.
            mstore(channelPtr, lastLayerEnd)
        }

        require(badInput == 0, "Invalid field element.");
        ctx[MM_FRI_LAST_LAYER_PTR] = lastLayerPtr;
    }

    function verifyProof(
        uint256[] memory proofParams,
        uint256[] memory proof,
        uint256[] memory publicInput
    ) internal view override {
        uint256[] memory ctx = initVerifierParams(publicInput, proofParams);
        uint256 channelPtr = getChannelPtr(ctx);

        initChannel(channelPtr, getProofPtr(proof), getPublicInputHash(publicInput));
        // Read trace commitment.
        ctx[MM_TRACE_COMMITMENT] = uint256(readHash(channelPtr, true));

        if (hasInteraction()) {
            // Send interaction elements.
            VerifierChannel.sendFieldElements(
                channelPtr,
                getNInteractionElements(),
                getPtr(ctx, getMmInteractionElements())
            );

            // Read second trace commitment.
            ctx[MM_TRACE_COMMITMENT + 1] = uint256(readHash(channelPtr, true));
        }

        VerifierChannel.sendFieldElements(
            channelPtr,
            getNCoefficients(),
            getPtr(ctx, getMmCoefficients())
        );
        ctx[MM_OODS_COMMITMENT] = uint256(readHash(channelPtr, true));

        // Send Out of Domain Sampling point.
        VerifierChannel.sendFieldElements(channelPtr, 1, getPtr(ctx, MM_OODS_POINT));

        // Read the answers to the Out of Domain Sampling.
        uint256 lmmOodsValues = getMmOodsValues();
        for (uint256 i = lmmOodsValues; i < lmmOodsValues + getNOodsValues(); i++) {
            ctx[i] = VerifierChannel.readFieldElement(channelPtr, true);
        }
        oodsConsistencyCheck(ctx);
        VerifierChannel.sendFieldElements(
            channelPtr,
            getNOodsCoefficients(),
            getPtr(ctx, getMmOodsCoefficients())
        );
        ctx[MM_FRI_COMMITMENTS] = uint256(VerifierChannel.readHash(channelPtr, true));

        uint256 nFriSteps = getFriStepSizes(ctx).length;
        uint256 fri_evalPointPtr = getPtr(ctx, MM_FRI_EVAL_POINTS);
        for (uint256 i = 1; i < nFriSteps - 1; i++) {
            VerifierChannel.sendFieldElements(channelPtr, 1, fri_evalPointPtr + i * 0x20);
            ctx[MM_FRI_COMMITMENTS + i] = uint256(VerifierChannel.readHash(channelPtr, true));
        }

        // Send last random FRI evaluation point.
        VerifierChannel.sendFieldElements(
            channelPtr,
            1,
            getPtr(ctx, MM_FRI_EVAL_POINTS + nFriSteps - 1)
        );

        // Read FRI last layer commitment.
        readLastFriLayer(ctx);

        // Generate queries.
        // emit LogGas("Read FRI commitments", gasleft());
        VerifierChannel.verifyProofOfWork(channelPtr, ctx[MM_PROOF_OF_WORK_BITS]);
        ctx[MM_N_UNIQUE_QUERIES] = VerifierChannel.sendRandomQueries(
            channelPtr,
            ctx[MM_N_UNIQUE_QUERIES],
            ctx[MM_EVAL_DOMAIN_SIZE] - 1,
            getPtr(ctx, MM_FRI_QUEUE),
            FRI_QUEUE_SLOT_SIZE_IN_BYTES
        );
        computeFirstFriLayer(ctx);

        friVerifyLayers(ctx);
    }
}

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Prng.sol";

/*
  Implements the communication channel from the verifier to the prover in the non-interactive case
  (See the BCS16 paper for more details).

  The state of the channel is stored in a uint256[3] as follows:
    [0] proof pointer.
    [1] prng digest.
    [2] prng counter.
*/
contract VerifierChannel is Prng {
    event LogValue(bytes32 val);

    event SendRandomnessEvent(uint256 val);

    event ReadFieldElementEvent(uint256 val);

    event ReadHashEvent(bytes32 val);

    function getPrngPtr(uint256 channelPtr) internal pure returns (uint256) {
        return channelPtr + 0x20;
    }

    function initChannel(
        uint256 channelPtr,
        uint256 proofPtr,
        bytes32 publicInputHash
    ) internal pure {
        assembly {
            // Skip 0x20 bytes length at the beginning of the proof.
            mstore(channelPtr, add(proofPtr, 0x20))
        }

        initPrng(getPrngPtr(channelPtr), publicInputHash);
    }

    /*
      Sends a field element through the verifier channel.

      Note that the logic of this function is inlined in many places throughout the code to reduce
      gas costs.
    */
    function sendFieldElements(
        uint256 channelPtr,
        uint256 nElements,
        uint256 targetPtr
    ) internal pure {
        require(nElements < 0x1000000, "Overflow protection failed.");
        assembly {
            // 31 * PRIME.
            let BOUND := 0xf80000000000020f00000000000000000000000000000000000000000000001f
            let digestPtr := add(channelPtr, 0x20)
            let counterPtr := add(channelPtr, 0x40)

            let endPtr := add(targetPtr, mul(nElements, 0x20))
            for {

            } lt(targetPtr, endPtr) {
                targetPtr := add(targetPtr, 0x20)
            } {
                // *targetPtr = getRandomFieldElement(getPrngPtr(channelPtr));

                let fieldElement := BOUND
                // while (fieldElement >= 31 * K_MODULUS).
                for {

                } iszero(lt(fieldElement, BOUND)) {

                } {
                    // keccak256(abi.encodePacked(digest, counter));
                    fieldElement := keccak256(digestPtr, 0x40)
                    // *counterPtr += 1;
                    mstore(counterPtr, add(mload(counterPtr), 1))
                }
                // *targetPtr = fromMontgomery(fieldElement);
                mstore(targetPtr, mulmod(fieldElement, K_MONTGOMERY_R_INV, K_MODULUS))
            }
        }
    }

    /*
      Sends random queries and returns an array of queries sorted in ascending order.
      Generates count queries in the range [0, mask] and returns the number of unique queries.
      Note that mask is of the form 2^k-1 (for some k <= 64).

      Note that queriesOutPtr may be (and is) interleaved with other arrays. The stride parameter
      is passed to indicate the distance between every two entries in the queries array, i.e.
      stride = 0x20*(number of interleaved arrays).
    */
    function sendRandomQueries(
        uint256 channelPtr,
        uint256 count,
        uint256 mask,
        uint256 queriesOutPtr,
        uint256 stride
    ) internal pure returns (uint256) {
        require(mask < 2**64, "mask must be < 2**64.");

        uint256 val;
        uint256 shift = 0;
        uint256 endPtr = queriesOutPtr;
        for (uint256 i = 0; i < count; i++) {
            if (shift == 0) {
                val = uint256(getRandomBytes(getPrngPtr(channelPtr)));
                shift = 0x100;
            }
            shift -= 0x40;
            uint256 queryIdx = (val >> shift) & mask;
            uint256 ptr = endPtr;

            // Initialize 'curr' to -1 to make sure the condition 'queryIdx != curr' is satisfied
            // on the first iteration.
            uint256 curr = uint256(-1);

            // Insert new queryIdx in the correct place like insertion sort.
            while (ptr > queriesOutPtr) {
                assembly {
                    curr := mload(sub(ptr, stride))
                }

                if (queryIdx >= curr) {
                    break;
                }

                assembly {
                    mstore(ptr, curr)
                }
                ptr -= stride;
            }

            if (queryIdx != curr) {
                assembly {
                    mstore(ptr, queryIdx)
                }
                endPtr += stride;
            } else {
                // Revert right shuffling.
                while (ptr < endPtr) {
                    assembly {
                        mstore(ptr, mload(add(ptr, stride)))
                        ptr := add(ptr, stride)
                    }
                }
            }
        }

        return (endPtr - queriesOutPtr) / stride;
    }

    function readBytes(uint256 channelPtr, bool mix) internal pure returns (bytes32) {
        uint256 proofPtr;
        bytes32 val;

        assembly {
            proofPtr := mload(channelPtr)
            val := mload(proofPtr)
            mstore(channelPtr, add(proofPtr, 0x20))
        }
        if (mix) {
            // Mix the bytes that were read into the state of the channel.
            assembly {
                let digestPtr := add(channelPtr, 0x20)
                let counterPtr := add(digestPtr, 0x20)

                // digest += 1.
                mstore(digestPtr, add(mload(digestPtr), 1))
                mstore(counterPtr, val)
                // prng.digest := keccak256(digest + 1||val), nonce was written earlier.
                mstore(digestPtr, keccak256(digestPtr, 0x40))
                // prng.counter := 0.
                mstore(counterPtr, 0)
            }
        }

        return val;
    }

    function readHash(uint256 channelPtr, bool mix) internal pure returns (bytes32) {
        bytes32 val = readBytes(channelPtr, mix);
        return val;
    }

    /*
      Reads a field element from the verifier channel (that is, the proof in the non-interactive
      case).
      The field elements on the channel are in Montgomery form and this function converts
      them to the standard representation.

      Note that the logic of this function is inlined in many places throughout the code to reduce
      gas costs.
    */
    function readFieldElement(uint256 channelPtr, bool mix) internal pure returns (uint256) {
        uint256 val = fromMontgomery(uint256(readBytes(channelPtr, mix)));

        return val;
    }

    function verifyProofOfWork(uint256 channelPtr, uint256 proofOfWorkBits) internal pure {
        if (proofOfWorkBits == 0) {
            return;
        }

        uint256 proofOfWorkDigest;
        assembly {
            // [0:0x29) := 0123456789abcded || digest     || workBits.
            //             8 bytes          || 0x20 bytes || 1 byte.
            mstore(0, 0x0123456789abcded000000000000000000000000000000000000000000000000)
            let digest := mload(add(channelPtr, 0x20))
            mstore(0x8, digest)
            mstore8(0x28, proofOfWorkBits)
            mstore(0, keccak256(0, 0x29))

            let proofPtr := mload(channelPtr)
            mstore(0x20, mload(proofPtr))
            // proofOfWorkDigest:= keccak256(keccak256(0123456789abcded || digest || workBits) || nonce).
            proofOfWorkDigest := keccak256(0, 0x28)

            mstore(0, add(digest, 1))
            // prng.digest := keccak256(digest + 1||nonce), nonce was written earlier.
            mstore(add(channelPtr, 0x20), keccak256(0, 0x28))
            // prng.counter := 0.
            mstore(add(channelPtr, 0x40), 0)

            mstore(channelPtr, add(proofPtr, 0x8))
        }

        uint256 proofOfWorkThreshold = uint256(1) << (256 - proofOfWorkBits);
        require(proofOfWorkDigest < proofOfWorkThreshold, "Proof of work check failed.");
    }
}