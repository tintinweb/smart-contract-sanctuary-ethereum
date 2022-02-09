/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract _bool {

    bool public condition = false;

    function setCondition(bool _state) public {
        condition = _state;
    }
}