// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract MappingContract {
    mapping(address => uint256) public balances;

    function updateBalance(address _user, uint256 _newBalance) public {
        balances[_user] = _newBalance;
    }
}