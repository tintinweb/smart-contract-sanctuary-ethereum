/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract _int {

    uint256 public _true = 0;
    uint256 public _false = 1;
    uint256 public condition;

    constructor() {
        condition = _false;
    }

    function setCondition(uint256 _state) public {
        condition = _state;
    }
}