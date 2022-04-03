// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Constructor {
    address public owner;
    uint public balance;

    constructor (uint _initBalance) {
        owner = msg.sender;
        balance = _initBalance;
    }

    function pause() external {

    }

    function unpause() external {
        
    }
}