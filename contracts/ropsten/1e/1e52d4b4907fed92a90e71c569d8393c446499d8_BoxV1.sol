/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV1 {
    uint public val;

    // no constructors for upgradeable contracts

    function initialize(uint _val) external {
        val = _val;
    }
}