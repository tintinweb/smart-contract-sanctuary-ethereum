/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: contracts/Helpers/GlideErrors.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// solhint-disable
library GlideErrors {
    // Liquid Staking
    uint256 internal constant UPDATE_EPOCH_NOT_ENOUGH_ELA = 101;
    uint256 internal constant RECEIVE_PAYLOAD_ADDRESS_ZERO = 102;
    uint256 internal constant REQUEST_WITHDRAW_NOT_ENOUGH_AMOUNT = 103;
    uint256 internal constant WITHDRAW_NOT_ENOUGH_AMOUNT = 104;
    uint256 internal constant WITHDRAW_TRANSFER_NOT_SUCCESS = 105;
    uint256 internal constant SET_STELA_TRANSFER_OWNER = 106;
    uint256 internal constant TRANSFER_STELA_OWNERSHIP = 107;
    uint256 internal constant EXCHANGE_RATE_MUST_BE_GREATER_OR_EQUAL_PREVIOUS =
        108;
    uint256 internal constant ELASTOS_MAINNET_ADDRESS_LENGTH = 109;
    uint256 internal constant EXCHANGE_RATE_UPPER_LIMIT = 110;
    uint256 internal constant STATUS_CANNOT_BE_ONHOLD = 111;
    uint256 internal constant STATUS_MUST_BE_ONHOLD = 112;

    // Liquid Staking Instant Swap
    uint256 internal constant FEE_RATE_IS_NOT_IN_RANGE = 201;
    uint256 internal constant NOT_ENOUGH_STELA_IN_CONTRACT = 202;
    uint256 internal constant NOT_ENOUGH_ELA_IN_CONTRACT = 203;
    uint256 internal constant SWAP_TRANSFER_NOT_SUCCEESS = 204;
    uint256 internal constant NO_ENOUGH_WITHDRAW_ELA_IN_CONTRACT = 205;

    /**
     * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
     * supported.
     */
    function _require(bool condition, uint256 errorCode) internal pure {
        if (!condition) _revert(errorCode);
    }

    /**
     * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
     */
    function _revert(uint256 errorCode) internal pure {
        // We're going to dynamically create a revert string based on the error code, with the following format:
        // 'GLIDE#{errorCode}'
        // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
        //
        // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
        // number (8 to 16 bits) than the individual string characters.
        //
        // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
        // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
        // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
        assembly {
            // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
            // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
            // the '0' character.

            let units := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let tenths := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let hundreds := add(mod(errorCode, 10), 0x30)

            // With the individual characters, we can now construct the full string. The "GLIDE#" part is a known constant
            // (0x474c49444523): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
            // characters to it, each shifted by a multiple of 8.
            // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
            // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
            // array).

            let revertReason := shl(
                184,
                add(
                    0x474c49444523000000,
                    add(add(units, shl(8, tenths)), shl(16, hundreds))
                )
            )

            // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
            // message will have the following layout:
            // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

            // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
            // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
            mstore(
                0x0,
                0x08c379a000000000000000000000000000000000000000000000000000000000
            )
            // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
            mstore(
                0x04,
                0x0000000000000000000000000000000000000000000000000000000000000020
            )
            // The string length is fixed: 7 characters.
            mstore(0x24, 9)
            // Finally, the string itself is stored.
            mstore(0x44, revertReason)

            // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
            // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
            revert(0, 100)
        }
    }
}