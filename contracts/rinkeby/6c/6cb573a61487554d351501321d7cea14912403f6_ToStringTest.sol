/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract ToStringTest {
    function _toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    function name0() external pure returns (string memory) {
        // Return the name of the contract.
        assembly {
            mstore(0, 0x20)
            mstore(0x27, 0x07536561706f7274)
            return(0, 0x60)
        }
    }

    function name1() external pure returns (string memory) {
        // Return the name of the contract.
        assembly {
            mstore(0, 0x20)
            mstore(0x40, 0x00)
            mstore(0x27, 0x07536561706f7274)
            return(0, 0x60)
        }
    }

    function toString1(uint256 x) external pure returns (string memory s) {
        s = _toString(x);
        assembly {
            mstore(mload(0x40), not(0))
        }
    }
}