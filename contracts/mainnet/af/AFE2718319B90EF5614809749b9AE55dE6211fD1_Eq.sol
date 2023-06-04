/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Eq {
    function isEq(uint256 a, uint256 b) external pure returns (uint256) {
        if (a == b){
            return 1;
        }
        return 0;
    }
}