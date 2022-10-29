/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Puretea {
    /// Check if the submitted EVM code is well formed. Allows state modification.
    function isMutating(bytes memory code) internal pure returns (bool) {
        return check(code, 0xe43f0000000000000000001fffffffffffffffff0fff01ffffff00013fff0fff);
    }

    /// Check if the submitted EVM code is well formed. Allows state reading.
    function isView(bytes memory code) internal pure returns (bool) {
        return check(code, 0x640800000000000000000000ffffffffffffffff0fdf01ffffff00013fff0fff);
    }

    /// Check if the submitted EVM code is well formed. Disallows state access beyond the current contract.
    function isPureGlobal(bytes memory code) internal pure returns (bool) {
        return check(code, 0x600800000000000000000000ffffffffffffffff0fdf01ff67ff00013fff0fff);
    }

    /// Check if the submitted EVM code is well formed. Disallows any state access.
    function isPureLocal(bytes memory code) internal pure returns (bool) {
        return check(code, 0x600800000000000000000000ffffffffffffffff0fcf01ffffff00013fff0fff);
    }

    /// Check the supplied EVM code against a mask of allowed opcodes and properly support PUSH instructions.
    /// Note that this will not perform jumpdest analysis, and it also does not suppor the Solidity metadata,
    /// which should be stripped upfront.
    ///
    /// Also note the mask is an reverse bitmask of allowed opcodes (lowest bit means opcode 0x00).
    function check(bytes memory _code, uint256 _mask) internal pure returns (bool satisfied) {
        assembly {
            function matchesMask(mask, opcode) -> ret {
                // Note: this function does no return a bool
                ret := and(mask, shl(opcode, 1))
            }

            function isPush(opcode) -> ret {
                // TODO: optimise
                ret := and(gt(opcode, 0x5f), lt(opcode, 0x80))
            }

            // Wrapping into a function to make use of the leave keyword
            // TODO: support leave within top level blocks to exit Solidity functions
            function perform(mask, code) -> ret {
                // TODO: instead of loading 1 byte, consider caching a slot?
                for {
                    let offset := add(code, 32)
                    let end := add(offset, mload(code ))
                } lt(offset, end) {
                    offset := add(offset, 1)
                } {
                    let opcode := byte(0, mload(offset))

                    // If opcode is not part of the mask
                    if iszero(matchesMask(mask, opcode)) {
                        // ret is set as false implicitly here
                        leave
                    }

                    // If opcode is a push instruction
                    if isPush(opcode) {
                        // Since we know that opcode is [0x60,x7f],
                        // this code is equivalent to add(and(opcode, 0x1f), 1)
                        let immLen := sub(opcode, 0x5f)
                        offset := add(offset, immLen)

                        // Check for push overreading
                        if iszero(lt(offset, end)) {
                            // ret is set as false implicitly here
                            leave
                        }
                    }
                }

                // checks have passed
                ret := 1
            }

            satisfied := perform(_mask, _code)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPurityChecker {
    /// @return True if the code of the given account satisfies the code purity requirements.
    function check(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPurityChecker} from "src/IPurityChecker.sol";

import {Puretea} from "puretea/Puretea.sol";

contract PurityChecker is IPurityChecker {
    // Allow non-state modifying opcodes only.
    uint256 private constant acceptedOpcodesMask = 0x600800000000000000000000ffffffffffffffff0fdf01ff67ff00013fff0fff;

    function check(address account) external view returns (bool) {
        return Puretea.check(account.code, acceptedOpcodesMask);
    }
}