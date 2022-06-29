/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Amount {
    uint256 public amount;
    constructor(uint256 _amount) {
        amount = _amount;
    }
}