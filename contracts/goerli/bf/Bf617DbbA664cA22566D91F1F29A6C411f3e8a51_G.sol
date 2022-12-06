/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract G {
    function x() public pure returns (uint256 a, uint256 b) {
        assembly {
            a := keccak256(0x00, 0x01)
            b := keccak256(0x00, 0x02)
        }
    }
}