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
    // [0x40, 0x60) - trace_length.
    // [0x60, 0x80) - offset_size.
    // [0x80, 0xa0) - half_offset_size.
    // [0xa0, 0xc0) - initial_ap.
    // [0xc0, 0xe0) - initial_pc.
    // [0xe0, 0x100) - final_ap.
    // [0x100, 0x120) - final_pc.
    // [0x120, 0x140) - memory/multi_column_perm/perm/interaction_elm.
    // [0x140, 0x160) - memory/multi_column_perm/hash_interaction_elm0.
    // [0x160, 0x180) - memory/multi_column_perm/perm/public_memory_prod.
    // [0x180, 0x1a0) - rc16/perm/interaction_elm.
    // [0x1a0, 0x1c0) - rc16/perm/public_memory_prod.
    // [0x1c0, 0x1e0) - rc_min.
    // [0x1e0, 0x200) - rc_max.
    // [0x200, 0x220) - diluted_check/permutation/interaction_elm.
    // [0x220, 0x240) - diluted_check/permutation/public_memory_prod.
    // [0x240, 0x260) - diluted_check/first_elm.
    // [0x260, 0x280) - diluted_check/interaction_z.
    // [0x280, 0x2a0) - diluted_check/interaction_alpha.
    // [0x2a0, 0x2c0) - diluted_check/final_cum_val.
    // [0x2c0, 0x2e0) - pedersen/shift_point.x.
    // [0x2e0, 0x300) - pedersen/shift_point.y.
    // [0x300, 0x320) - initial_pedersen_addr.
    // [0x320, 0x340) - initial_rc_addr.
    // [0x340, 0x360) - initial_bitwise_addr.
    // [0x360, 0x380) - trace_generator.
    // [0x380, 0x3a0) - oods_point.
    // [0x3a0, 0x460) - interaction_elements.
    // [0x460, 0x1000) - coefficients.
    // [0x1000, 0x20a0) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x20a0, 0x20c0) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x20c0, 0x20e0) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x20e0, 0x2100) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x2100, 0x2120) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x2120, 0x2140) - intermediate_value/cpu/decode/flag_op1_base_op0_0.
    // [0x2140, 0x2160) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x2160, 0x2180) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x2180, 0x21a0) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x21a0, 0x21c0) - intermediate_value/cpu/decode/flag_res_op1_0.
    // [0x21c0, 0x21e0) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x21e0, 0x2200) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x2200, 0x2220) - intermediate_value/cpu/decode/flag_pc_update_regular_0.
    // [0x2220, 0x2240) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x2240, 0x2260) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x2260, 0x2280) - intermediate_value/cpu/decode/fp_update_regular_0.
    // [0x2280, 0x22a0) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x22a0, 0x22c0) - intermediate_value/npc_reg_0.
    // [0x22c0, 0x22e0) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x22e0, 0x2300) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x2300, 0x2320) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x2320, 0x2340) - intermediate_value/memory/address_diff_0.
    // [0x2340, 0x2360) - intermediate_value/rc16/diff_0.
    // [0x2360, 0x2380) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x2380, 0x23a0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x23a0, 0x23c0) - intermediate_value/rc_builtin/value0_0.
    // [0x23c0, 0x23e0) - intermediate_value/rc_builtin/value1_0.
    // [0x23e0, 0x2400) - intermediate_value/rc_builtin/value2_0.
    // [0x2400, 0x2420) - intermediate_value/rc_builtin/value3_0.
    // [0x2420, 0x2440) - intermediate_value/rc_builtin/value4_0.
    // [0x2440, 0x2460) - intermediate_value/rc_builtin/value5_0.
    // [0x2460, 0x2480) - intermediate_value/rc_builtin/value6_0.
    // [0x2480, 0x24a0) - intermediate_value/rc_builtin/value7_0.
    // [0x24a0, 0x24c0) - intermediate_value/bitwise/sum_var_0_0.
    // [0x24c0, 0x24e0) - intermediate_value/bitwise/sum_var_8_0.
    // [0x24e0, 0x2920) - expmods.
    // [0x2920, 0x2bc0) - domains.
    // [0x2bc0, 0x2de0) - denominator_invs.
    // [0x2de0, 0x3000) - denominators.
    // [0x3000, 0x30c0) - expmod_context.

    fallback() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x20a0)
            let point := /*oods_point*/ mload(0x380)
            function expmod(base, exponent, modulus) -> result {
              let p := /*expmod_context*/ 0x3000
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

              // expmods[0] = point^(trace_length / 2048).
              mstore(0x24e0, expmod(point, div(/*trace_length*/ mload(0x40), 2048), PRIME))

              // expmods[1] = point^(trace_length / 1024).
              mstore(0x2500, mulmod(
                /*point^(trace_length / 2048)*/ mload(0x24e0),
                /*point^(trace_length / 2048)*/ mload(0x24e0),
                PRIME))

              // expmods[2] = point^(trace_length / 128).
              mstore(0x2520, expmod(point, div(/*trace_length*/ mload(0x40), 128), PRIME))

              // expmods[3] = point^(trace_length / 32).
              mstore(0x2540, expmod(point, div(/*trace_length*/ mload(0x40), 32), PRIME))

              // expmods[4] = point^(trace_length / 16).
              mstore(0x2560, mulmod(
                /*point^(trace_length / 32)*/ mload(0x2540),
                /*point^(trace_length / 32)*/ mload(0x2540),
                PRIME))

              // expmods[5] = point^(trace_length / 4).
              mstore(0x2580, expmod(point, div(/*trace_length*/ mload(0x40), 4), PRIME))

              // expmods[6] = point^(trace_length / 2).
              mstore(0x25a0, mulmod(
                /*point^(trace_length / 4)*/ mload(0x2580),
                /*point^(trace_length / 4)*/ mload(0x2580),
                PRIME))

              // expmods[7] = point^trace_length.
              mstore(0x25c0, mulmod(
                /*point^(trace_length / 2)*/ mload(0x25a0),
                /*point^(trace_length / 2)*/ mload(0x25a0),
                PRIME))

              // expmods[8] = trace_generator^(trace_length / 64).
              mstore(0x25e0, expmod(/*trace_generator*/ mload(0x360), div(/*trace_length*/ mload(0x40), 64), PRIME))

              // expmods[9] = trace_generator^(trace_length / 32).
              mstore(0x2600, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                PRIME))

              // expmods[10] = trace_generator^(3 * trace_length / 64).
              mstore(0x2620, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(trace_length / 32)*/ mload(0x2600),
                PRIME))

              // expmods[11] = trace_generator^(trace_length / 16).
              mstore(0x2640, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(3 * trace_length / 64)*/ mload(0x2620),
                PRIME))

              // expmods[12] = trace_generator^(5 * trace_length / 64).
              mstore(0x2660, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(trace_length / 16)*/ mload(0x2640),
                PRIME))

              // expmods[13] = trace_generator^(3 * trace_length / 32).
              mstore(0x2680, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(5 * trace_length / 64)*/ mload(0x2660),
                PRIME))

              // expmods[14] = trace_generator^(7 * trace_length / 64).
              mstore(0x26a0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(3 * trace_length / 32)*/ mload(0x2680),
                PRIME))

              // expmods[15] = trace_generator^(trace_length / 8).
              mstore(0x26c0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(7 * trace_length / 64)*/ mload(0x26a0),
                PRIME))

              // expmods[16] = trace_generator^(9 * trace_length / 64).
              mstore(0x26e0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(trace_length / 8)*/ mload(0x26c0),
                PRIME))

              // expmods[17] = trace_generator^(5 * trace_length / 32).
              mstore(0x2700, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(9 * trace_length / 64)*/ mload(0x26e0),
                PRIME))

              // expmods[18] = trace_generator^(11 * trace_length / 64).
              mstore(0x2720, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(5 * trace_length / 32)*/ mload(0x2700),
                PRIME))

              // expmods[19] = trace_generator^(3 * trace_length / 16).
              mstore(0x2740, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(11 * trace_length / 64)*/ mload(0x2720),
                PRIME))

              // expmods[20] = trace_generator^(13 * trace_length / 64).
              mstore(0x2760, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(3 * trace_length / 16)*/ mload(0x2740),
                PRIME))

              // expmods[21] = trace_generator^(7 * trace_length / 32).
              mstore(0x2780, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(13 * trace_length / 64)*/ mload(0x2760),
                PRIME))

              // expmods[22] = trace_generator^(15 * trace_length / 64).
              mstore(0x27a0, mulmod(
                /*trace_generator^(trace_length / 64)*/ mload(0x25e0),
                /*trace_generator^(7 * trace_length / 32)*/ mload(0x2780),
                PRIME))

              // expmods[23] = trace_generator^(trace_length / 2).
              mstore(0x27c0, expmod(/*trace_generator*/ mload(0x360), div(/*trace_length*/ mload(0x40), 2), PRIME))

              // expmods[24] = trace_generator^(3 * trace_length / 4).
              mstore(0x27e0, expmod(/*trace_generator*/ mload(0x360), div(mul(3, /*trace_length*/ mload(0x40)), 4), PRIME))

              // expmods[25] = trace_generator^(15 * trace_length / 16).
              mstore(0x2800, mulmod(
                /*trace_generator^(3 * trace_length / 16)*/ mload(0x2740),
                /*trace_generator^(3 * trace_length / 4)*/ mload(0x27e0),
                PRIME))

              // expmods[26] = trace_generator^(63 * trace_length / 64).
              mstore(0x2820, mulmod(
                /*trace_generator^(3 * trace_length / 64)*/ mload(0x2620),
                /*trace_generator^(15 * trace_length / 16)*/ mload(0x2800),
                PRIME))

              // expmods[27] = trace_generator^(255 * trace_length / 256).
              mstore(0x2840, expmod(/*trace_generator*/ mload(0x360), div(mul(255, /*trace_length*/ mload(0x40)), 256), PRIME))

              // expmods[28] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x2860, expmod(/*trace_generator*/ mload(0x360), mul(16, sub(div(/*trace_length*/ mload(0x40), 16), 1)), PRIME))

              // expmods[29] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x2880, expmod(/*trace_generator*/ mload(0x360), mul(2, sub(div(/*trace_length*/ mload(0x40), 2), 1)), PRIME))

              // expmods[30] = trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x28a0, expmod(/*trace_generator*/ mload(0x360), mul(4, sub(div(/*trace_length*/ mload(0x40), 4), 1)), PRIME))

              // expmods[31] = trace_generator^(trace_length - 1).
              mstore(0x28c0, expmod(/*trace_generator*/ mload(0x360), sub(/*trace_length*/ mload(0x40), 1), PRIME))

              // expmods[32] = trace_generator^(2048 * (trace_length / 2048 - 1)).
              mstore(0x28e0, expmod(/*trace_generator*/ mload(0x360), mul(2048, sub(div(/*trace_length*/ mload(0x40), 2048), 1)), PRIME))

              // expmods[33] = trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x2900, expmod(/*trace_generator*/ mload(0x360), mul(128, sub(div(/*trace_length*/ mload(0x40), 128), 1)), PRIME))

            }

            {
              // Compute domains.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'diluted_check/permutation/step0', 'diluted_check/step'.
              // domains[0] = point^trace_length - 1.
              mstore(0x2920,
                     addmod(/*point^trace_length*/ mload(0x25c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // domains[1] = point^(trace_length / 2) - 1.
              mstore(0x2940,
                     addmod(/*point^(trace_length / 2)*/ mload(0x25a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc16/perm/step0', 'rc16/diff_is_bit', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // domains[2] = point^(trace_length / 4) - 1.
              mstore(0x2960,
                     addmod(/*point^(trace_length / 4)*/ mload(0x2580), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/zero'.
              // Numerator for constraints: 'cpu/decode/opcode_rc/bit'.
              // domains[3] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x2980,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x2560),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x2800)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/decode/flag_op1_base_op0_bit', 'cpu/decode/flag_res_op1_bit', 'cpu/decode/flag_pc_update_regular_bit', 'cpu/decode/fp_update_regular_bit', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/call/off0', 'cpu/opcodes/call/off1', 'cpu/opcodes/call/flags', 'cpu/opcodes/ret/off0', 'cpu/opcodes/ret/off2', 'cpu/opcodes/ret/flags', 'cpu/opcodes/assert_eq/assert_eq', 'public_memory_addr_zero', 'public_memory_value_zero'.
              // domains[4] = point^(trace_length / 16) - 1.
              mstore(0x29a0,
                     addmod(/*point^(trace_length / 16)*/ mload(0x2560), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'bitwise/step_var_pool_addr', 'bitwise/partition'.
              // domains[5] = point^(trace_length / 32) - 1.
              mstore(0x29c0,
                     addmod(/*point^(trace_length / 32)*/ mload(0x2540), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc_builtin/value', 'rc_builtin/addr_step', 'bitwise/x_or_y_addr', 'bitwise/next_var_pool_addr', 'bitwise/or_is_and_plus_xor', 'bitwise/unique_unpacking192', 'bitwise/unique_unpacking193', 'bitwise/unique_unpacking194', 'bitwise/unique_unpacking195'.
              // domains[6] = point^(trace_length / 128) - 1.
              mstore(0x29e0,
                     addmod(/*point^(trace_length / 128)*/ mload(0x2520), sub(PRIME, 1), PRIME))

              // Numerator for constraints: 'bitwise/step_var_pool_addr'.
              // domains[7] = point^(trace_length / 128) - trace_generator^(3 * trace_length / 4).
              mstore(0x2a00,
                     addmod(
                       /*point^(trace_length / 128)*/ mload(0x2520),
                       sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x27e0)),
                       PRIME))

              // Denominator for constraints: 'bitwise/addition_is_xor_with_and'.
              // domains[8] = (point^(trace_length / 128) - trace_generator^(trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 16)) * (point^(trace_length / 128) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 8)) * (point^(trace_length / 128) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 128) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(15 * trace_length / 64)) * domain6.
              {
                let domain := mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(trace_length / 64)*/ mload(0x25e0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(trace_length / 32)*/ mload(0x2600)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 128)*/ mload(0x2520),
                        sub(PRIME, /*trace_generator^(3 * trace_length / 64)*/ mload(0x2620)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 128)*/ mload(0x2520),
                      sub(PRIME, /*trace_generator^(trace_length / 16)*/ mload(0x2640)),
                      PRIME),
                    PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 64)*/ mload(0x2660)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(3 * trace_length / 32)*/ mload(0x2680)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 128)*/ mload(0x2520),
                        sub(PRIME, /*trace_generator^(7 * trace_length / 64)*/ mload(0x26a0)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 128)*/ mload(0x2520),
                      sub(PRIME, /*trace_generator^(trace_length / 8)*/ mload(0x26c0)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(9 * trace_length / 64)*/ mload(0x26e0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 32)*/ mload(0x2700)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 128)*/ mload(0x2520),
                        sub(PRIME, /*trace_generator^(11 * trace_length / 64)*/ mload(0x2720)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 128)*/ mload(0x2520),
                      sub(PRIME, /*trace_generator^(3 * trace_length / 16)*/ mload(0x2740)),
                      PRIME),
                    PRIME),
                  PRIME)
                domain := mulmod(
                  domain,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(13 * trace_length / 64)*/ mload(0x2760)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 128)*/ mload(0x2520),
                          sub(PRIME, /*trace_generator^(7 * trace_length / 32)*/ mload(0x2780)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 128)*/ mload(0x2520),
                        sub(PRIME, /*trace_generator^(15 * trace_length / 64)*/ mload(0x27a0)),
                        PRIME),
                      PRIME),
                    /*domains[6]*/ mload(0x29e0),
                    PRIME),
                  PRIME)
                mstore(0x2a20, domain)
              }

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y'.
              // domains[9] = point^(trace_length / 1024) - 1.
              mstore(0x2a40,
                     addmod(/*point^(trace_length / 1024)*/ mload(0x2500), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail'.
              // Numerator for constraints: 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // domains[10] = point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              mstore(0x2a60,
                     addmod(
                       /*point^(trace_length / 1024)*/ mload(0x2500),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x2840)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end'.
              // domains[11] = point^(trace_length / 1024) - trace_generator^(63 * trace_length / 64).
              mstore(0x2a80,
                     addmod(
                       /*point^(trace_length / 1024)*/ mload(0x2500),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x2820)),
                       PRIME))

              // Numerator for constraints: 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y'.
              // domains[12] = point^(trace_length / 2048) - trace_generator^(trace_length / 2).
              mstore(0x2aa0,
                     addmod(
                       /*point^(trace_length / 2048)*/ mload(0x24e0),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x27c0)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/input0_value0', 'pedersen/input0_addr', 'pedersen/input1_value0', 'pedersen/input1_addr', 'pedersen/output_value0', 'pedersen/output_addr'.
              // domains[13] = point^(trace_length / 2048) - 1.
              mstore(0x2ac0,
                     addmod(/*point^(trace_length / 2048)*/ mload(0x24e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_fp', 'final_pc'.
              // Numerator for constraints: 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // domains[14] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x2ae0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x2860)),
                       PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'memory/initial_addr', 'rc16/perm/init0', 'rc16/minimum', 'diluted_check/permutation/init0', 'diluted_check/init', 'diluted_check/first_element', 'pedersen/init_addr', 'rc_builtin/init_addr', 'bitwise/init_var_pool_addr'.
              // domains[15] = point - 1.
              mstore(0x2b00,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last'.
              // Numerator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // domains[16] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x2b20,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x2880)),
                       PRIME))

              // Denominator for constraints: 'rc16/perm/last', 'rc16/maximum'.
              // Numerator for constraints: 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // domains[17] = point - trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x2b40,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4 * (trace_length / 4 - 1))*/ mload(0x28a0)),
                       PRIME))

              // Denominator for constraints: 'diluted_check/permutation/last', 'diluted_check/last'.
              // Numerator for constraints: 'diluted_check/permutation/step0', 'diluted_check/step'.
              // domains[18] = point - trace_generator^(trace_length - 1).
              mstore(0x2b60,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x28c0)), PRIME))

              // Numerator for constraints: 'pedersen/input0_addr'.
              // domains[19] = point - trace_generator^(2048 * (trace_length / 2048 - 1)).
              mstore(0x2b80,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2048 * (trace_length / 2048 - 1))*/ mload(0x28e0)),
                       PRIME))

              // Numerator for constraints: 'rc_builtin/addr_step', 'bitwise/next_var_pool_addr'.
              // domains[20] = point - trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x2ba0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(128 * (trace_length / 128 - 1))*/ mload(0x2900)),
                       PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // denominators[0] = domains[0].
              mstore(0x2de0, /*domains[0]*/ mload(0x2920))

              // denominators[1] = domains[3].
              mstore(0x2e00, /*domains[3]*/ mload(0x2980))

              // denominators[2] = domains[4].
              mstore(0x2e20, /*domains[4]*/ mload(0x29a0))

              // denominators[3] = domains[14].
              mstore(0x2e40, /*domains[14]*/ mload(0x2ae0))

              // denominators[4] = domains[15].
              mstore(0x2e60, /*domains[15]*/ mload(0x2b00))

              // denominators[5] = domains[1].
              mstore(0x2e80, /*domains[1]*/ mload(0x2940))

              // denominators[6] = domains[16].
              mstore(0x2ea0, /*domains[16]*/ mload(0x2b20))

              // denominators[7] = domains[2].
              mstore(0x2ec0, /*domains[2]*/ mload(0x2960))

              // denominators[8] = domains[17].
              mstore(0x2ee0, /*domains[17]*/ mload(0x2b40))

              // denominators[9] = domains[18].
              mstore(0x2f00, /*domains[18]*/ mload(0x2b60))

              // denominators[10] = domains[9].
              mstore(0x2f20, /*domains[9]*/ mload(0x2a40))

              // denominators[11] = domains[10].
              mstore(0x2f40, /*domains[10]*/ mload(0x2a60))

              // denominators[12] = domains[11].
              mstore(0x2f60, /*domains[11]*/ mload(0x2a80))

              // denominators[13] = domains[13].
              mstore(0x2f80, /*domains[13]*/ mload(0x2ac0))

              // denominators[14] = domains[6].
              mstore(0x2fa0, /*domains[6]*/ mload(0x29e0))

              // denominators[15] = domains[5].
              mstore(0x2fc0, /*domains[5]*/ mload(0x29c0))

              // denominators[16] = domains[8].
              mstore(0x2fe0, /*domains[8]*/ mload(0x2a20))

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x220
              let prod := 1
              let partialProductEndPtr := 0x2de0
              for { let partialProductPtr := 0x2bc0 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x2bc0
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
              let currentPartialProductPtr := 0x2de0
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
                /*column0_row0*/ mload(0x1000),
                sub(
                  PRIME,
                  addmod(/*column0_row1*/ mload(0x1020), /*column0_row1*/ mload(0x1020), PRIME)),
                PRIME)
              mstore(0x20a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column0_row2 - (column0_row3 + column0_row3).
              let val := addmod(
                /*column0_row2*/ mload(0x1040),
                sub(
                  PRIME,
                  addmod(/*column0_row3*/ mload(0x1060), /*column0_row3*/ mload(0x1060), PRIME)),
                PRIME)
              mstore(0x20c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column0_row4 - (column0_row5 + column0_row5).
              let val := addmod(
                /*column0_row4*/ mload(0x1080),
                sub(
                  PRIME,
                  addmod(/*column0_row5*/ mload(0x10a0), /*column0_row5*/ mload(0x10a0), PRIME)),
                PRIME)
              mstore(0x20e0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column0_row3 - (column0_row4 + column0_row4).
              let val := addmod(
                /*column0_row3*/ mload(0x1060),
                sub(
                  PRIME,
                  addmod(/*column0_row4*/ mload(0x1080), /*column0_row4*/ mload(0x1080), PRIME)),
                PRIME)
              mstore(0x2100, val)
              }


              {
              // cpu/decode/flag_op1_base_op0_0 = 1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x20c0),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x20e0),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x2100),
                    PRIME)),
                PRIME)
              mstore(0x2120, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column0_row5 - (column0_row6 + column0_row6).
              let val := addmod(
                /*column0_row5*/ mload(0x10a0),
                sub(
                  PRIME,
                  addmod(/*column0_row6*/ mload(0x10c0), /*column0_row6*/ mload(0x10c0), PRIME)),
                PRIME)
              mstore(0x2140, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column0_row6 - (column0_row7 + column0_row7).
              let val := addmod(
                /*column0_row6*/ mload(0x10c0),
                sub(
                  PRIME,
                  addmod(/*column0_row7*/ mload(0x10e0), /*column0_row7*/ mload(0x10e0), PRIME)),
                PRIME)
              mstore(0x2160, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column0_row9 - (column0_row10 + column0_row10).
              let val := addmod(
                /*column0_row9*/ mload(0x1120),
                sub(
                  PRIME,
                  addmod(/*column0_row10*/ mload(0x1140), /*column0_row10*/ mload(0x1140), PRIME)),
                PRIME)
              mstore(0x2180, val)
              }


              {
              // cpu/decode/flag_res_op1_0 = 1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x2140),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x2160),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180),
                    PRIME)),
                PRIME)
              mstore(0x21a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column0_row7 - (column0_row8 + column0_row8).
              let val := addmod(
                /*column0_row7*/ mload(0x10e0),
                sub(
                  PRIME,
                  addmod(/*column0_row8*/ mload(0x1100), /*column0_row8*/ mload(0x1100), PRIME)),
                PRIME)
              mstore(0x21c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column0_row8 - (column0_row9 + column0_row9).
              let val := addmod(
                /*column0_row8*/ mload(0x1100),
                sub(
                  PRIME,
                  addmod(/*column0_row9*/ mload(0x1120), /*column0_row9*/ mload(0x1120), PRIME)),
                PRIME)
              mstore(0x21e0, val)
              }


              {
              // cpu/decode/flag_pc_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x21c0),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x21e0),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180),
                    PRIME)),
                PRIME)
              mstore(0x2200, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column0_row12 - (column0_row13 + column0_row13).
              let val := addmod(
                /*column0_row12*/ mload(0x1180),
                sub(
                  PRIME,
                  addmod(/*column0_row13*/ mload(0x11a0), /*column0_row13*/ mload(0x11a0), PRIME)),
                PRIME)
              mstore(0x2220, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column0_row13 - (column0_row14 + column0_row14).
              let val := addmod(
                /*column0_row13*/ mload(0x11a0),
                sub(
                  PRIME,
                  addmod(/*column0_row14*/ mload(0x11c0), /*column0_row14*/ mload(0x11c0), PRIME)),
                PRIME)
              mstore(0x2240, val)
              }


              {
              // cpu/decode/fp_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x2240),
                    PRIME)),
                PRIME)
              mstore(0x2260, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column0_row1 - (column0_row2 + column0_row2).
              let val := addmod(
                /*column0_row1*/ mload(0x1020),
                sub(
                  PRIME,
                  addmod(/*column0_row2*/ mload(0x1040), /*column0_row2*/ mload(0x1040), PRIME)),
                PRIME)
              mstore(0x2280, val)
              }


              {
              // npc_reg_0 = column3_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column3_row0*/ mload(0x1620),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x20c0),
                  PRIME),
                1,
                PRIME)
              mstore(0x22a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column0_row10 - (column0_row11 + column0_row11).
              let val := addmod(
                /*column0_row10*/ mload(0x1140),
                sub(
                  PRIME,
                  addmod(/*column0_row11*/ mload(0x1160), /*column0_row11*/ mload(0x1160), PRIME)),
                PRIME)
              mstore(0x22c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column0_row11 - (column0_row12 + column0_row12).
              let val := addmod(
                /*column0_row11*/ mload(0x1160),
                sub(
                  PRIME,
                  addmod(/*column0_row12*/ mload(0x1180), /*column0_row12*/ mload(0x1180), PRIME)),
                PRIME)
              mstore(0x22e0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column0_row14 - (column0_row15 + column0_row15).
              let val := addmod(
                /*column0_row14*/ mload(0x11c0),
                sub(
                  PRIME,
                  addmod(/*column0_row15*/ mload(0x11e0), /*column0_row15*/ mload(0x11e0), PRIME)),
                PRIME)
              mstore(0x2300, val)
              }


              {
              // memory/address_diff_0 = column4_row2 - column4_row0.
              let val := addmod(/*column4_row2*/ mload(0x1a20), sub(PRIME, /*column4_row0*/ mload(0x19e0)), PRIME)
              mstore(0x2320, val)
              }


              {
              // rc16/diff_0 = column5_row6 - column5_row2.
              let val := addmod(/*column5_row6*/ mload(0x1b20), sub(PRIME, /*column5_row2*/ mload(0x1aa0)), PRIME)
              mstore(0x2340, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column6_row0 - (column6_row4 + column6_row4).
              let val := addmod(
                /*column6_row0*/ mload(0x1d20),
                sub(
                  PRIME,
                  addmod(/*column6_row4*/ mload(0x1da0), /*column6_row4*/ mload(0x1da0), PRIME)),
                PRIME)
              mstore(0x2360, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360)),
                PRIME)
              mstore(0x2380, val)
              }


              {
              // rc_builtin/value0_0 = column5_row12.
              let val := /*column5_row12*/ mload(0x1b80)
              mstore(0x23a0, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column5_row28.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x23a0),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row28*/ mload(0x1ba0),
                PRIME)
              mstore(0x23c0, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column5_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x23c0),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row44*/ mload(0x1bc0),
                PRIME)
              mstore(0x23e0, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column5_row60.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x23e0),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row60*/ mload(0x1be0),
                PRIME)
              mstore(0x2400, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column5_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x2400),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row76*/ mload(0x1c00),
                PRIME)
              mstore(0x2420, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column5_row92.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x2420),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row92*/ mload(0x1c20),
                PRIME)
              mstore(0x2440, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column5_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x2440),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row108*/ mload(0x1c40),
                PRIME)
              mstore(0x2460, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column5_row124.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x2460),
                  /*offset_size*/ mload(0x60),
                  PRIME),
                /*column5_row124*/ mload(0x1c60),
                PRIME)
              mstore(0x2480, val)
              }


              {
              // bitwise/sum_var_0_0 = column1_row0 + column1_row2 * 2 + column1_row4 * 4 + column1_row6 * 8 + column1_row8 * 18446744073709551616 + column1_row10 * 36893488147419103232 + column1_row12 * 73786976294838206464 + column1_row14 * 147573952589676412928.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            /*column1_row0*/ mload(0x1200),
                            mulmod(/*column1_row2*/ mload(0x1240), 2, PRIME),
                            PRIME),
                          mulmod(/*column1_row4*/ mload(0x1260), 4, PRIME),
                          PRIME),
                        mulmod(/*column1_row6*/ mload(0x1280), 8, PRIME),
                        PRIME),
                      mulmod(/*column1_row8*/ mload(0x12a0), 18446744073709551616, PRIME),
                      PRIME),
                    mulmod(/*column1_row10*/ mload(0x12c0), 36893488147419103232, PRIME),
                    PRIME),
                  mulmod(/*column1_row12*/ mload(0x12e0), 73786976294838206464, PRIME),
                  PRIME),
                mulmod(/*column1_row14*/ mload(0x1300), 147573952589676412928, PRIME),
                PRIME)
              mstore(0x24a0, val)
              }


              {
              // bitwise/sum_var_8_0 = column1_row16 * 340282366920938463463374607431768211456 + column1_row18 * 680564733841876926926749214863536422912 + column1_row20 * 1361129467683753853853498429727072845824 + column1_row22 * 2722258935367507707706996859454145691648 + column1_row24 * 6277101735386680763835789423207666416102355444464034512896 + column1_row26 * 12554203470773361527671578846415332832204710888928069025792 + column1_row28 * 25108406941546723055343157692830665664409421777856138051584 + column1_row30 * 50216813883093446110686315385661331328818843555712276103168.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            mulmod(/*column1_row16*/ mload(0x1320), 340282366920938463463374607431768211456, PRIME),
                            mulmod(/*column1_row18*/ mload(0x1340), 680564733841876926926749214863536422912, PRIME),
                            PRIME),
                          mulmod(/*column1_row20*/ mload(0x1360), 1361129467683753853853498429727072845824, PRIME),
                          PRIME),
                        mulmod(/*column1_row22*/ mload(0x1380), 2722258935367507707706996859454145691648, PRIME),
                        PRIME),
                      mulmod(
                        /*column1_row24*/ mload(0x13a0),
                        6277101735386680763835789423207666416102355444464034512896,
                        PRIME),
                      PRIME),
                    mulmod(
                      /*column1_row26*/ mload(0x13c0),
                      12554203470773361527671578846415332832204710888928069025792,
                      PRIME),
                    PRIME),
                  mulmod(
                    /*column1_row28*/ mload(0x13e0),
                    25108406941546723055343157692830665664409421777856138051584,
                    PRIME),
                  PRIME),
                mulmod(
                  /*column1_row30*/ mload(0x1400),
                  50216813883093446110686315385661331328818843555712276103168,
                  PRIME),
                PRIME)
              mstore(0x24c0, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= domains[3].
              val := mulmod(val, /*domains[3]*/ mload(0x2980), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x2bc0), PRIME)

              // res += val * coefficients[0].
              res := addmod(res,
                            mulmod(val, /*coefficients[0]*/ mload(0x460), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/zero: column0_row0.
              let val := /*column0_row0*/ mload(0x1000)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, /*denominator_invs[1]*/ mload(0x2be0), PRIME)

              // res += val * coefficients[1].
              res := addmod(res,
                            mulmod(val, /*coefficients[1]*/ mload(0x480), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column3_row1 - (((column0_row0 * offset_size + column5_row4) * offset_size + column5_row8) * offset_size + column5_row0).
              let val := addmod(
                /*column3_row1*/ mload(0x1640),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column0_row0*/ mload(0x1000), /*offset_size*/ mload(0x60), PRIME),
                            /*column5_row4*/ mload(0x1ae0),
                            PRIME),
                          /*offset_size*/ mload(0x60),
                          PRIME),
                        /*column5_row8*/ mload(0x1b60),
                        PRIME),
                      /*offset_size*/ mload(0x60),
                      PRIME),
                    /*column5_row0*/ mload(0x1a60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[2].
              res := addmod(res,
                            mulmod(val, /*coefficients[2]*/ mload(0x4a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_op1_base_op0_bit: cpu__decode__flag_op1_base_op0_0 * cpu__decode__flag_op1_base_op0_0 - cpu__decode__flag_op1_base_op0_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x2120),
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x2120),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x2120)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[3].
              res := addmod(res,
                            mulmod(val, /*coefficients[3]*/ mload(0x4c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_res_op1_bit: cpu__decode__flag_res_op1_0 * cpu__decode__flag_res_op1_0 - cpu__decode__flag_res_op1_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x21a0),
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x21a0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x21a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[4].
              res := addmod(res,
                            mulmod(val, /*coefficients[4]*/ mload(0x4e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_pc_update_regular_bit: cpu__decode__flag_pc_update_regular_0 * cpu__decode__flag_pc_update_regular_0 - cpu__decode__flag_pc_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x2200),
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x2200),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x2200)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[5].
              res := addmod(res,
                            mulmod(val, /*coefficients[5]*/ mload(0x500), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/fp_update_regular_bit: cpu__decode__fp_update_regular_0 * cpu__decode__fp_update_regular_0 - cpu__decode__fp_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x2260),
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x2260),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x2260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[6].
              res := addmod(res,
                            mulmod(val, /*coefficients[6]*/ mload(0x520), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column3_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column6_row9 + (1 - cpu__decode__opcode_rc__bit_0) * column6_row1 + column5_row0).
              let val := addmod(
                addmod(/*column3_row8*/ mload(0x16e0), /*half_offset_size*/ mload(0x80), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0),
                        /*column6_row9*/ mload(0x1e00),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0)),
                          PRIME),
                        /*column6_row1*/ mload(0x1d40),
                        PRIME),
                      PRIME),
                    /*column5_row0*/ mload(0x1a60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[7].
              res := addmod(res,
                            mulmod(val, /*coefficients[7]*/ mload(0x540), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column3_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column6_row9 + (1 - cpu__decode__opcode_rc__bit_1) * column6_row1 + column5_row8).
              let val := addmod(
                addmod(/*column3_row4*/ mload(0x16a0), /*half_offset_size*/ mload(0x80), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x2280),
                        /*column6_row9*/ mload(0x1e00),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x2280)),
                          PRIME),
                        /*column6_row1*/ mload(0x1d40),
                        PRIME),
                      PRIME),
                    /*column5_row8*/ mload(0x1b60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[8].
              res := addmod(res,
                            mulmod(val, /*coefficients[8]*/ mload(0x560), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column3_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column3_row0 + cpu__decode__opcode_rc__bit_4 * column6_row1 + cpu__decode__opcode_rc__bit_3 * column6_row9 + cpu__decode__flag_op1_base_op0_0 * column3_row5 + column5_row4).
              let val := addmod(
                addmod(/*column3_row12*/ mload(0x1760), /*half_offset_size*/ mload(0x80), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x20c0),
                            /*column3_row0*/ mload(0x1620),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x20e0),
                            /*column6_row1*/ mload(0x1d40),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x2100),
                          /*column6_row9*/ mload(0x1e00),
                          PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x2120),
                        /*column3_row5*/ mload(0x16c0),
                        PRIME),
                      PRIME),
                    /*column5_row4*/ mload(0x1ae0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[9].
              res := addmod(res,
                            mulmod(val, /*coefficients[9]*/ mload(0x580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column6_row5 - column3_row5 * column3_row13.
              let val := addmod(
                /*column6_row5*/ mload(0x1dc0),
                sub(
                  PRIME,
                  mulmod(/*column3_row5*/ mload(0x16c0), /*column3_row13*/ mload(0x1780), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[10].
              res := addmod(res,
                            mulmod(val, /*coefficients[10]*/ mload(0x5a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column6_row13 - (cpu__decode__opcode_rc__bit_5 * (column3_row5 + column3_row13) + cpu__decode__opcode_rc__bit_6 * column6_row5 + cpu__decode__flag_res_op1_0 * column3_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180)),
                    PRIME),
                  /*column6_row13*/ mload(0x1e40),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x2140),
                        addmod(/*column3_row5*/ mload(0x16c0), /*column3_row13*/ mload(0x1780), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x2160),
                        /*column6_row5*/ mload(0x1dc0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x21a0),
                      /*column3_row13*/ mload(0x1780),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[11].
              res := addmod(res,
                            mulmod(val, /*coefficients[11]*/ mload(0x5c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column6_row3 - cpu__decode__opcode_rc__bit_9 * column3_row9.
              let val := addmod(
                /*column6_row3*/ mload(0x1d80),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180),
                    /*column3_row9*/ mload(0x1700),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[12].
              res := addmod(res,
                            mulmod(val, /*coefficients[12]*/ mload(0x5e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column6_row11 - column6_row3 * column6_row13.
              let val := addmod(
                /*column6_row11*/ mload(0x1e20),
                sub(
                  PRIME,
                  mulmod(/*column6_row3*/ mload(0x1d80), /*column6_row13*/ mload(0x1e40), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[13].
              res := addmod(res,
                            mulmod(val, /*coefficients[13]*/ mload(0x600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column3_row16 + column6_row3 * (column3_row16 - (column3_row0 + column3_row13)) - (cpu__decode__flag_pc_update_regular_0 * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column6_row13 + cpu__decode__opcode_rc__bit_8 * (column3_row0 + column6_row13)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180)),
                      PRIME),
                    /*column3_row16*/ mload(0x17a0),
                    PRIME),
                  mulmod(
                    /*column6_row3*/ mload(0x1d80),
                    addmod(
                      /*column3_row16*/ mload(0x17a0),
                      sub(
                        PRIME,
                        addmod(/*column3_row0*/ mload(0x1620), /*column3_row13*/ mload(0x1780), PRIME)),
                      PRIME),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x2200),
                        /*intermediate_value/npc_reg_0*/ mload(0x22a0),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x21c0),
                        /*column6_row13*/ mload(0x1e40),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x21e0),
                      addmod(/*column3_row0*/ mload(0x1620), /*column6_row13*/ mload(0x1e40), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[14].
              res := addmod(res,
                            mulmod(val, /*coefficients[14]*/ mload(0x620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column6_row11 - cpu__decode__opcode_rc__bit_9) * (column3_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column6_row11*/ mload(0x1e20),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x2180)),
                  PRIME),
                addmod(
                  /*column3_row16*/ mload(0x17a0),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x22a0)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[15].
              res := addmod(res,
                            mulmod(val, /*coefficients[15]*/ mload(0x640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column6_row17 - (column6_row1 + cpu__decode__opcode_rc__bit_10 * column6_row13 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column6_row17*/ mload(0x1e60),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column6_row1*/ mload(0x1d40),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x22c0),
                          /*column6_row13*/ mload(0x1e40),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x22e0),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[16].
              res := addmod(res,
                            mulmod(val, /*coefficients[16]*/ mload(0x660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column6_row25 - (cpu__decode__fp_update_regular_0 * column6_row9 + cpu__decode__opcode_rc__bit_13 * column3_row9 + cpu__decode__opcode_rc__bit_12 * (column6_row1 + 2)).
              let val := addmod(
                /*column6_row25*/ mload(0x1e80),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x2260),
                        /*column6_row9*/ mload(0x1e00),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x2240),
                        /*column3_row9*/ mload(0x1700),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                      addmod(/*column6_row1*/ mload(0x1d40), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= domains[14].
              val := mulmod(val, /*domains[14]*/ mload(0x2ae0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[17].
              res := addmod(res,
                            mulmod(val, /*coefficients[17]*/ mload(0x680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column3_row9 - column6_row9).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                addmod(/*column3_row9*/ mload(0x1700), sub(PRIME, /*column6_row9*/ mload(0x1e00)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[18].
              res := addmod(res,
                            mulmod(val, /*coefficients[18]*/ mload(0x6a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column3_row5 - (column3_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                addmod(
                  /*column3_row5*/ mload(0x16c0),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column3_row0*/ mload(0x1620),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x20c0),
                        PRIME),
                      1,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[19].
              res := addmod(res,
                            mulmod(val, /*coefficients[19]*/ mload(0x6c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off0: cpu__decode__opcode_rc__bit_12 * (column5_row0 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                addmod(/*column5_row0*/ mload(0x1a60), sub(PRIME, /*half_offset_size*/ mload(0x80)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[20].
              res := addmod(res,
                            mulmod(val, /*coefficients[20]*/ mload(0x6e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off1: cpu__decode__opcode_rc__bit_12 * (column5_row8 - (half_offset_size + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                addmod(
                  /*column5_row8*/ mload(0x1b60),
                  sub(PRIME, addmod(/*half_offset_size*/ mload(0x80), 1, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[21].
              res := addmod(res,
                            mulmod(val, /*coefficients[21]*/ mload(0x700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/flags: cpu__decode__opcode_rc__bit_12 * (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_12 + 1 + 1 - (cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_1 + 4)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x2220),
                        PRIME),
                      1,
                      PRIME),
                    1,
                    PRIME),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x2280),
                        PRIME),
                      4,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[22].
              res := addmod(res,
                            mulmod(val, /*coefficients[22]*/ mload(0x720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off0: cpu__decode__opcode_rc__bit_13 * (column5_row0 + 2 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x2240),
                addmod(
                  addmod(/*column5_row0*/ mload(0x1a60), 2, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0x80)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[23].
              res := addmod(res,
                            mulmod(val, /*coefficients[23]*/ mload(0x740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off2: cpu__decode__opcode_rc__bit_13 * (column5_row4 + 1 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x2240),
                addmod(
                  addmod(/*column5_row4*/ mload(0x1ae0), 1, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0x80)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[24].
              res := addmod(res,
                            mulmod(val, /*coefficients[24]*/ mload(0x760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/flags: cpu__decode__opcode_rc__bit_13 * (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_3 + cpu__decode__flag_res_op1_0 - 4).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x2240),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x21c0),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x20a0),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x2100),
                      PRIME),
                    /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x21a0),
                    PRIME),
                  sub(PRIME, 4),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[25].
              res := addmod(res,
                            mulmod(val, /*coefficients[25]*/ mload(0x780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column3_row9 - column6_row13).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x2300),
                addmod(/*column3_row9*/ mload(0x1700), sub(PRIME, /*column6_row13*/ mload(0x1e40)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[26].
              res := addmod(res,
                            mulmod(val, /*coefficients[26]*/ mload(0x7a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_ap: column6_row1 - initial_ap.
              let val := addmod(/*column6_row1*/ mload(0x1d40), sub(PRIME, /*initial_ap*/ mload(0xa0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[27].
              res := addmod(res,
                            mulmod(val, /*coefficients[27]*/ mload(0x7c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_fp: column6_row9 - initial_ap.
              let val := addmod(/*column6_row9*/ mload(0x1e00), sub(PRIME, /*initial_ap*/ mload(0xa0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[28].
              res := addmod(res,
                            mulmod(val, /*coefficients[28]*/ mload(0x7e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_pc: column3_row0 - initial_pc.
              let val := addmod(/*column3_row0*/ mload(0x1620), sub(PRIME, /*initial_pc*/ mload(0xc0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[29].
              res := addmod(res,
                            mulmod(val, /*coefficients[29]*/ mload(0x800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_ap: column6_row1 - final_ap.
              let val := addmod(/*column6_row1*/ mload(0x1d40), sub(PRIME, /*final_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x2c20), PRIME)

              // res += val * coefficients[30].
              res := addmod(res,
                            mulmod(val, /*coefficients[30]*/ mload(0x820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_fp: column6_row9 - initial_ap.
              let val := addmod(/*column6_row9*/ mload(0x1e00), sub(PRIME, /*initial_ap*/ mload(0xa0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x2c20), PRIME)

              // res += val * coefficients[31].
              res := addmod(res,
                            mulmod(val, /*coefficients[31]*/ mload(0x840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_pc: column3_row0 - final_pc.
              let val := addmod(/*column3_row0*/ mload(0x1620), sub(PRIME, /*final_pc*/ mload(0x100)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[3].
              val := mulmod(val, /*denominator_invs[3]*/ mload(0x2c20), PRIME)

              // res += val * coefficients[32].
              res := addmod(res,
                            mulmod(val, /*coefficients[32]*/ mload(0x860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column4_row0 + memory/multi_column_perm/hash_interaction_elm0 * column4_row1)) * column9_inter1_row0 + column3_row0 + memory/multi_column_perm/hash_interaction_elm0 * column3_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x120),
                        sub(
                          PRIME,
                          addmod(
                            /*column4_row0*/ mload(0x19e0),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x140),
                              /*column4_row1*/ mload(0x1a00),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column9_inter1_row0*/ mload(0x2020),
                      PRIME),
                    /*column3_row0*/ mload(0x1620),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x140),
                    /*column3_row1*/ mload(0x1640),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x120)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[33].
              res := addmod(res,
                            mulmod(val, /*coefficients[33]*/ mload(0x880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column4_row2 + memory/multi_column_perm/hash_interaction_elm0 * column4_row3)) * column9_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column3_row2 + memory/multi_column_perm/hash_interaction_elm0 * column3_row3)) * column9_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x120),
                    sub(
                      PRIME,
                      addmod(
                        /*column4_row2*/ mload(0x1a20),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x140),
                          /*column4_row3*/ mload(0x1a40),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column9_inter1_row2*/ mload(0x2060),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x120),
                      sub(
                        PRIME,
                        addmod(
                          /*column3_row2*/ mload(0x1660),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x140),
                            /*column3_row3*/ mload(0x1680),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column9_inter1_row0*/ mload(0x2020),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[16].
              val := mulmod(val, /*domains[16]*/ mload(0x2b20), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x2c60), PRIME)

              // res += val * coefficients[34].
              res := addmod(res,
                            mulmod(val, /*coefficients[34]*/ mload(0x8a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column9_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row0*/ mload(0x2020),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, /*denominator_invs[6]*/ mload(0x2c80), PRIME)

              // res += val * coefficients[35].
              res := addmod(res,
                            mulmod(val, /*coefficients[35]*/ mload(0x8c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x2320),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x2320),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x2320)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[16].
              val := mulmod(val, /*domains[16]*/ mload(0x2b20), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x2c60), PRIME)

              // res += val * coefficients[36].
              res := addmod(res,
                            mulmod(val, /*coefficients[36]*/ mload(0x8e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column4_row1 - column4_row3).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x2320), sub(PRIME, 1), PRIME),
                addmod(/*column4_row1*/ mload(0x1a00), sub(PRIME, /*column4_row3*/ mload(0x1a40)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= domains[16].
              val := mulmod(val, /*domains[16]*/ mload(0x2b20), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, /*denominator_invs[5]*/ mload(0x2c60), PRIME)

              // res += val * coefficients[37].
              res := addmod(res,
                            mulmod(val, /*coefficients[37]*/ mload(0x900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/initial_addr: column4_row0 - 1.
              let val := addmod(/*column4_row0*/ mload(0x19e0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[38].
              res := addmod(res,
                            mulmod(val, /*coefficients[38]*/ mload(0x920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column3_row2.
              let val := /*column3_row2*/ mload(0x1660)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[39].
              res := addmod(res,
                            mulmod(val, /*coefficients[39]*/ mload(0x940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column3_row3.
              let val := /*column3_row3*/ mload(0x1680)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, /*denominator_invs[2]*/ mload(0x2c00), PRIME)

              // res += val * coefficients[40].
              res := addmod(res,
                            mulmod(val, /*coefficients[40]*/ mload(0x960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column5_row2) * column9_inter1_row1 + column5_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x180),
                      sub(PRIME, /*column5_row2*/ mload(0x1aa0)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x2040),
                    PRIME),
                  /*column5_row0*/ mload(0x1a60),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x180)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[41].
              res := addmod(res,
                            mulmod(val, /*coefficients[41]*/ mload(0x980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column5_row6) * column9_inter1_row5 - (rc16/perm/interaction_elm - column5_row4) * column9_inter1_row1.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x180),
                    sub(PRIME, /*column5_row6*/ mload(0x1b20)),
                    PRIME),
                  /*column9_inter1_row5*/ mload(0x2080),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x180),
                      sub(PRIME, /*column5_row4*/ mload(0x1ae0)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x2040),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= domains[17].
              val := mulmod(val, /*domains[17]*/ mload(0x2b40), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[42].
              res := addmod(res,
                            mulmod(val, /*coefficients[42]*/ mload(0x9a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column9_inter1_row1 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row1*/ mload(0x2040),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x1a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x2cc0), PRIME)

              // res += val * coefficients[43].
              res := addmod(res,
                            mulmod(val, /*coefficients[43]*/ mload(0x9c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x2340),
                  /*intermediate_value/rc16/diff_0*/ mload(0x2340),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x2340)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= domains[17].
              val := mulmod(val, /*domains[17]*/ mload(0x2b40), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[44].
              res := addmod(res,
                            mulmod(val, /*coefficients[44]*/ mload(0x9e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column5_row2 - rc_min.
              let val := addmod(/*column5_row2*/ mload(0x1aa0), sub(PRIME, /*rc_min*/ mload(0x1c0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[45].
              res := addmod(res,
                            mulmod(val, /*coefficients[45]*/ mload(0xa00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column5_row2 - rc_max.
              let val := addmod(/*column5_row2*/ mload(0x1aa0), sub(PRIME, /*rc_max*/ mload(0x1e0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[8].
              val := mulmod(val, /*denominator_invs[8]*/ mload(0x2cc0), PRIME)

              // res += val * coefficients[46].
              res := addmod(res,
                            mulmod(val, /*coefficients[46]*/ mload(0xa20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/init0: (diluted_check/permutation/interaction_elm - column2_row0) * column8_inter1_row0 + column1_row0 - diluted_check/permutation/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x200),
                      sub(PRIME, /*column2_row0*/ mload(0x15e0)),
                      PRIME),
                    /*column8_inter1_row0*/ mload(0x1fe0),
                    PRIME),
                  /*column1_row0*/ mload(0x1200),
                  PRIME),
                sub(PRIME, /*diluted_check/permutation/interaction_elm*/ mload(0x200)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[47].
              res := addmod(res,
                            mulmod(val, /*coefficients[47]*/ mload(0xa40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/step0: (diluted_check/permutation/interaction_elm - column2_row1) * column8_inter1_row1 - (diluted_check/permutation/interaction_elm - column1_row1) * column8_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*diluted_check/permutation/interaction_elm*/ mload(0x200),
                    sub(PRIME, /*column2_row1*/ mload(0x1600)),
                    PRIME),
                  /*column8_inter1_row1*/ mload(0x2000),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x200),
                      sub(PRIME, /*column1_row1*/ mload(0x1220)),
                      PRIME),
                    /*column8_inter1_row0*/ mload(0x1fe0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x2b60), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x2bc0), PRIME)

              // res += val * coefficients[48].
              res := addmod(res,
                            mulmod(val, /*coefficients[48]*/ mload(0xa60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/last: column8_inter1_row0 - diluted_check/permutation/public_memory_prod.
              let val := addmod(
                /*column8_inter1_row0*/ mload(0x1fe0),
                sub(PRIME, /*diluted_check/permutation/public_memory_prod*/ mload(0x220)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x2ce0), PRIME)

              // res += val * coefficients[49].
              res := addmod(res,
                            mulmod(val, /*coefficients[49]*/ mload(0xa80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/init: column7_inter1_row0 - 1.
              let val := addmod(/*column7_inter1_row0*/ mload(0x1fa0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[50].
              res := addmod(res,
                            mulmod(val, /*coefficients[50]*/ mload(0xaa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/first_element: column2_row0 - diluted_check/first_elm.
              let val := addmod(
                /*column2_row0*/ mload(0x15e0),
                sub(PRIME, /*diluted_check/first_elm*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[51].
              res := addmod(res,
                            mulmod(val, /*coefficients[51]*/ mload(0xac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/step: column7_inter1_row1 - (column7_inter1_row0 * (1 + diluted_check/interaction_z * (column2_row1 - column2_row0)) + diluted_check/interaction_alpha * (column2_row1 - column2_row0) * (column2_row1 - column2_row0)).
              let val := addmod(
                /*column7_inter1_row1*/ mload(0x1fc0),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      /*column7_inter1_row0*/ mload(0x1fa0),
                      addmod(
                        1,
                        mulmod(
                          /*diluted_check/interaction_z*/ mload(0x260),
                          addmod(/*column2_row1*/ mload(0x1600), sub(PRIME, /*column2_row0*/ mload(0x15e0)), PRIME),
                          PRIME),
                        PRIME),
                      PRIME),
                    mulmod(
                      mulmod(
                        /*diluted_check/interaction_alpha*/ mload(0x280),
                        addmod(/*column2_row1*/ mload(0x1600), sub(PRIME, /*column2_row0*/ mload(0x15e0)), PRIME),
                        PRIME),
                      addmod(/*column2_row1*/ mload(0x1600), sub(PRIME, /*column2_row0*/ mload(0x15e0)), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= domains[18].
              val := mulmod(val, /*domains[18]*/ mload(0x2b60), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, /*denominator_invs[0]*/ mload(0x2bc0), PRIME)

              // res += val * coefficients[52].
              res := addmod(res,
                            mulmod(val, /*coefficients[52]*/ mload(0xae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/last: column7_inter1_row0 - diluted_check/final_cum_val.
              let val := addmod(
                /*column7_inter1_row0*/ mload(0x1fa0),
                sub(PRIME, /*diluted_check/final_cum_val*/ mload(0x2a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[9].
              val := mulmod(val, /*denominator_invs[9]*/ mload(0x2ce0), PRIME)

              // res += val * coefficients[53].
              res := addmod(res,
                            mulmod(val, /*coefficients[53]*/ mload(0xb00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero: column6_row7 * (column6_row0 - (column6_row4 + column6_row4)).
              let val := mulmod(
                /*column6_row7*/ mload(0x1de0),
                addmod(
                  /*column6_row0*/ mload(0x1d20),
                  sub(
                    PRIME,
                    addmod(/*column6_row4*/ mload(0x1da0), /*column6_row4*/ mload(0x1da0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[54].
              res := addmod(res,
                            mulmod(val, /*coefficients[54]*/ mload(0xb20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column6_row7 * (column6_row4 - 3138550867693340381917894711603833208051177722232017256448 * column6_row768).
              let val := mulmod(
                /*column6_row7*/ mload(0x1de0),
                addmod(
                  /*column6_row4*/ mload(0x1da0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column6_row768*/ mload(0x1ea0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[55].
              res := addmod(res,
                            mulmod(val, /*coefficients[55]*/ mload(0xb40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192: column6_row7 - column6_row1022 * (column6_row768 - (column6_row772 + column6_row772)).
              let val := addmod(
                /*column6_row7*/ mload(0x1de0),
                sub(
                  PRIME,
                  mulmod(
                    /*column6_row1022*/ mload(0x1f60),
                    addmod(
                      /*column6_row768*/ mload(0x1ea0),
                      sub(
                        PRIME,
                        addmod(/*column6_row772*/ mload(0x1ec0), /*column6_row772*/ mload(0x1ec0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[56].
              res := addmod(res,
                            mulmod(val, /*coefficients[56]*/ mload(0xb60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column6_row1022 * (column6_row772 - 8 * column6_row784).
              let val := mulmod(
                /*column6_row1022*/ mload(0x1f60),
                addmod(
                  /*column6_row772*/ mload(0x1ec0),
                  sub(PRIME, mulmod(8, /*column6_row784*/ mload(0x1ee0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[57].
              res := addmod(res,
                            mulmod(val, /*coefficients[57]*/ mload(0xb80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196: column6_row1022 - (column6_row1004 - (column6_row1008 + column6_row1008)) * (column6_row784 - (column6_row788 + column6_row788)).
              let val := addmod(
                /*column6_row1022*/ mload(0x1f60),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column6_row1004*/ mload(0x1f20),
                      sub(
                        PRIME,
                        addmod(/*column6_row1008*/ mload(0x1f40), /*column6_row1008*/ mload(0x1f40), PRIME)),
                      PRIME),
                    addmod(
                      /*column6_row784*/ mload(0x1ee0),
                      sub(
                        PRIME,
                        addmod(/*column6_row788*/ mload(0x1f00), /*column6_row788*/ mload(0x1f00), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[58].
              res := addmod(res,
                            mulmod(val, /*coefficients[58]*/ mload(0xba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column6_row1004 - (column6_row1008 + column6_row1008)) * (column6_row788 - 18014398509481984 * column6_row1004).
              let val := mulmod(
                addmod(
                  /*column6_row1004*/ mload(0x1f20),
                  sub(
                    PRIME,
                    addmod(/*column6_row1008*/ mload(0x1f40), /*column6_row1008*/ mload(0x1f40), PRIME)),
                  PRIME),
                addmod(
                  /*column6_row788*/ mload(0x1f00),
                  sub(PRIME, mulmod(18014398509481984, /*column6_row1004*/ mload(0x1f20), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[59].
              res := addmod(res,
                            mulmod(val, /*coefficients[59]*/ mload(0xbc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[60].
              res := addmod(res,
                            mulmod(val, /*coefficients[60]*/ mload(0xbe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column6_row0.
              let val := /*column6_row0*/ mload(0x1d20)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[12].
              val := mulmod(val, /*denominator_invs[12]*/ mload(0x2d40), PRIME)

              // res += val * coefficients[61].
              res := addmod(res,
                            mulmod(val, /*coefficients[61]*/ mload(0xc00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column6_row0.
              let val := /*column6_row0*/ mload(0x1d20)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[11].
              val := mulmod(val, /*denominator_invs[11]*/ mload(0x2d20), PRIME)

              // res += val * coefficients[62].
              res := addmod(res,
                            mulmod(val, /*coefficients[62]*/ mload(0xc20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column5_row3 - pedersen__points__y) - column6_row2 * (column5_row1 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360),
                  addmod(
                    /*column5_row3*/ mload(0x1ac0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column6_row2*/ mload(0x1d60),
                    addmod(
                      /*column5_row1*/ mload(0x1a80),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[63].
              res := addmod(res,
                            mulmod(val, /*coefficients[63]*/ mload(0xc40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column6_row2 * column6_row2 - pedersen__hash0__ec_subset_sum__bit_0 * (column5_row1 + pedersen__points__x + column5_row5).
              let val := addmod(
                mulmod(/*column6_row2*/ mload(0x1d60), /*column6_row2*/ mload(0x1d60), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360),
                    addmod(
                      addmod(
                        /*column5_row1*/ mload(0x1a80),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column5_row5*/ mload(0x1b00),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[64].
              res := addmod(res,
                            mulmod(val, /*coefficients[64]*/ mload(0xc60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column5_row3 + column5_row7) - column6_row2 * (column5_row1 - column5_row5).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x2360),
                  addmod(/*column5_row3*/ mload(0x1ac0), /*column5_row7*/ mload(0x1b40), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column6_row2*/ mload(0x1d60),
                    addmod(/*column5_row1*/ mload(0x1a80), sub(PRIME, /*column5_row5*/ mload(0x1b00)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[65].
              res := addmod(res,
                            mulmod(val, /*coefficients[65]*/ mload(0xc80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column5_row5 - column5_row1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x2380),
                addmod(/*column5_row5*/ mload(0x1b00), sub(PRIME, /*column5_row1*/ mload(0x1a80)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[66].
              res := addmod(res,
                            mulmod(val, /*coefficients[66]*/ mload(0xca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column5_row7 - column5_row3).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x2380),
                addmod(/*column5_row7*/ mload(0x1b40), sub(PRIME, /*column5_row3*/ mload(0x1ac0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 1024) - trace_generator^(255 * trace_length / 256).
              // val *= domains[10].
              val := mulmod(val, /*domains[10]*/ mload(0x2a60), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, /*denominator_invs[7]*/ mload(0x2ca0), PRIME)

              // res += val * coefficients[67].
              res := addmod(res,
                            mulmod(val, /*coefficients[67]*/ mload(0xcc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column5_row1025 - column5_row1021.
              let val := addmod(
                /*column5_row1025*/ mload(0x1cc0),
                sub(PRIME, /*column5_row1021*/ mload(0x1c80)),
                PRIME)

              // Numerator: point^(trace_length / 2048) - trace_generator^(trace_length / 2).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x2aa0), PRIME)
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[68].
              res := addmod(res,
                            mulmod(val, /*coefficients[68]*/ mload(0xce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column5_row1027 - column5_row1023.
              let val := addmod(
                /*column5_row1027*/ mload(0x1ce0),
                sub(PRIME, /*column5_row1023*/ mload(0x1ca0)),
                PRIME)

              // Numerator: point^(trace_length / 2048) - trace_generator^(trace_length / 2).
              // val *= domains[12].
              val := mulmod(val, /*domains[12]*/ mload(0x2aa0), PRIME)
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, /*denominator_invs[10]*/ mload(0x2d00), PRIME)

              // res += val * coefficients[69].
              res := addmod(res,
                            mulmod(val, /*coefficients[69]*/ mload(0xd00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column5_row1 - pedersen/shift_point.x.
              let val := addmod(
                /*column5_row1*/ mload(0x1a80),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x2c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[70].
              res := addmod(res,
                            mulmod(val, /*coefficients[70]*/ mload(0xd20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column5_row3 - pedersen/shift_point.y.
              let val := addmod(
                /*column5_row3*/ mload(0x1ac0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[71].
              res := addmod(res,
                            mulmod(val, /*coefficients[71]*/ mload(0xd40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column3_row11 - column6_row0.
              let val := addmod(/*column3_row11*/ mload(0x1740), sub(PRIME, /*column6_row0*/ mload(0x1d20)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[72].
              res := addmod(res,
                            mulmod(val, /*coefficients[72]*/ mload(0xd60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column3_row2058 - (column3_row522 + 1).
              let val := addmod(
                /*column3_row2058*/ mload(0x19c0),
                sub(PRIME, addmod(/*column3_row522*/ mload(0x1940), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2048 * (trace_length / 2048 - 1)).
              // val *= domains[19].
              val := mulmod(val, /*domains[19]*/ mload(0x2b80), PRIME)
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[73].
              res := addmod(res,
                            mulmod(val, /*coefficients[73]*/ mload(0xd80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column3_row10 - initial_pedersen_addr.
              let val := addmod(
                /*column3_row10*/ mload(0x1720),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[74].
              res := addmod(res,
                            mulmod(val, /*coefficients[74]*/ mload(0xda0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column3_row1035 - column6_row1024.
              let val := addmod(
                /*column3_row1035*/ mload(0x19a0),
                sub(PRIME, /*column6_row1024*/ mload(0x1f80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[75].
              res := addmod(res,
                            mulmod(val, /*coefficients[75]*/ mload(0xdc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column3_row1034 - (column3_row10 + 1).
              let val := addmod(
                /*column3_row1034*/ mload(0x1980),
                sub(PRIME, addmod(/*column3_row10*/ mload(0x1720), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[76].
              res := addmod(res,
                            mulmod(val, /*coefficients[76]*/ mload(0xde0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column3_row523 - column5_row2045.
              let val := addmod(
                /*column3_row523*/ mload(0x1960),
                sub(PRIME, /*column5_row2045*/ mload(0x1d00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[77].
              res := addmod(res,
                            mulmod(val, /*coefficients[77]*/ mload(0xe00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column3_row522 - (column3_row1034 + 1).
              let val := addmod(
                /*column3_row522*/ mload(0x1940),
                sub(PRIME, addmod(/*column3_row1034*/ mload(0x1980), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 2048) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, /*denominator_invs[13]*/ mload(0x2d60), PRIME)

              // res += val * coefficients[78].
              res := addmod(res,
                            mulmod(val, /*coefficients[78]*/ mload(0xe20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column3_row75.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x2480),
                sub(PRIME, /*column3_row75*/ mload(0x1880)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[79].
              res := addmod(res,
                            mulmod(val, /*coefficients[79]*/ mload(0xe40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column3_row202 - (column3_row74 + 1).
              let val := addmod(
                /*column3_row202*/ mload(0x1920),
                sub(PRIME, addmod(/*column3_row74*/ mload(0x1860), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= domains[20].
              val := mulmod(val, /*domains[20]*/ mload(0x2ba0), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[80].
              res := addmod(res,
                            mulmod(val, /*coefficients[80]*/ mload(0xe60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column3_row74 - initial_rc_addr.
              let val := addmod(
                /*column3_row74*/ mload(0x1860),
                sub(PRIME, /*initial_rc_addr*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[81].
              res := addmod(res,
                            mulmod(val, /*coefficients[81]*/ mload(0xe80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/init_var_pool_addr: column3_row26 - initial_bitwise_addr.
              let val := addmod(
                /*column3_row26*/ mload(0x17c0),
                sub(PRIME, /*initial_bitwise_addr*/ mload(0x340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point - 1.
              // val *= denominator_invs[4].
              val := mulmod(val, /*denominator_invs[4]*/ mload(0x2c40), PRIME)

              // res += val * coefficients[82].
              res := addmod(res,
                            mulmod(val, /*coefficients[82]*/ mload(0xea0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/step_var_pool_addr: column3_row58 - (column3_row26 + 1).
              let val := addmod(
                /*column3_row58*/ mload(0x1840),
                sub(PRIME, addmod(/*column3_row26*/ mload(0x17c0), 1, PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 128) - trace_generator^(3 * trace_length / 4).
              // val *= domains[7].
              val := mulmod(val, /*domains[7]*/ mload(0x2a00), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x2da0), PRIME)

              // res += val * coefficients[83].
              res := addmod(res,
                            mulmod(val, /*coefficients[83]*/ mload(0xec0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/x_or_y_addr: column3_row42 - (column3_row122 + 1).
              let val := addmod(
                /*column3_row42*/ mload(0x1800),
                sub(PRIME, addmod(/*column3_row122*/ mload(0x18c0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[84].
              res := addmod(res,
                            mulmod(val, /*coefficients[84]*/ mload(0xee0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/next_var_pool_addr: column3_row154 - (column3_row42 + 1).
              let val := addmod(
                /*column3_row154*/ mload(0x1900),
                sub(PRIME, addmod(/*column3_row42*/ mload(0x1800), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= domains[20].
              val := mulmod(val, /*domains[20]*/ mload(0x2ba0), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[85].
              res := addmod(res,
                            mulmod(val, /*coefficients[85]*/ mload(0xf00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/partition: bitwise__sum_var_0_0 + bitwise__sum_var_8_0 - column3_row27.
              let val := addmod(
                addmod(
                  /*intermediate_value/bitwise/sum_var_0_0*/ mload(0x24a0),
                  /*intermediate_value/bitwise/sum_var_8_0*/ mload(0x24c0),
                  PRIME),
                sub(PRIME, /*column3_row27*/ mload(0x17e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, /*denominator_invs[15]*/ mload(0x2da0), PRIME)

              // res += val * coefficients[86].
              res := addmod(res,
                            mulmod(val, /*coefficients[86]*/ mload(0xf20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/or_is_and_plus_xor: column3_row43 - (column3_row91 + column3_row123).
              let val := addmod(
                /*column3_row43*/ mload(0x1820),
                sub(
                  PRIME,
                  addmod(/*column3_row91*/ mload(0x18a0), /*column3_row123*/ mload(0x18e0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[87].
              res := addmod(res,
                            mulmod(val, /*coefficients[87]*/ mload(0xf40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/addition_is_xor_with_and: column1_row0 + column1_row32 - (column1_row96 + column1_row64 + column1_row64).
              let val := addmod(
                addmod(/*column1_row0*/ mload(0x1200), /*column1_row32*/ mload(0x1420), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column1_row96*/ mload(0x1520), /*column1_row64*/ mload(0x1460), PRIME),
                    /*column1_row64*/ mload(0x1460),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: (point^(trace_length / 128) - trace_generator^(trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 16)) * (point^(trace_length / 128) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(trace_length / 8)) * (point^(trace_length / 128) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 128) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 128) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 128) - trace_generator^(15 * trace_length / 64)) * domain6.
              // val *= denominator_invs[16].
              val := mulmod(val, /*denominator_invs[16]*/ mload(0x2dc0), PRIME)

              // res += val * coefficients[88].
              res := addmod(res,
                            mulmod(val, /*coefficients[88]*/ mload(0xf60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking192: (column1_row88 + column1_row120) * 16 - column1_row1.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row88*/ mload(0x14a0), /*column1_row120*/ mload(0x1560), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row1*/ mload(0x1220)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[89].
              res := addmod(res,
                            mulmod(val, /*coefficients[89]*/ mload(0xf80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking193: (column1_row90 + column1_row122) * 16 - column1_row65.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row90*/ mload(0x14c0), /*column1_row122*/ mload(0x1580), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row65*/ mload(0x1480)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[90].
              res := addmod(res,
                            mulmod(val, /*coefficients[90]*/ mload(0xfa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking194: (column1_row92 + column1_row124) * 16 - column1_row33.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row92*/ mload(0x14e0), /*column1_row124*/ mload(0x15a0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row33*/ mload(0x1440)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[91].
              res := addmod(res,
                            mulmod(val, /*coefficients[91]*/ mload(0xfc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking195: (column1_row94 + column1_row126) * 256 - column1_row97.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row94*/ mload(0x1500), /*column1_row126*/ mload(0x15c0), PRIME),
                  256,
                  PRIME),
                sub(PRIME, /*column1_row97*/ mload(0x1540)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, /*denominator_invs[14]*/ mload(0x2d80), PRIME)

              // res += val * coefficients[92].
              res := addmod(res,
                            mulmod(val, /*coefficients[92]*/ mload(0xfe0), PRIME),
                            PRIME)
              }

            mstore(0, res)
            return(0, 0x20)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------