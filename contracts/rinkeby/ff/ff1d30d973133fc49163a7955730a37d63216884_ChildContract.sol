/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ChildContract {
    address public owner;
    uint public num;

    constructor() {
        owner = msg.sender;
    }

    function store(uint _num) public {
        num = _num;
    }
}