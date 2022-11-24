/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MadToken {

    mapping(address => mapping (string => uint256))  userBalances;

    function openAccount(address owner, string memory token) public returns (bool) {
        userBalances[owner][token] = 40000;
        return true;
    }

    function getBalance(address owner, string  memory token) public view returns (uint256) {
        return userBalances[owner][token];
    }

    function addBalance(address owner,string memory token, uint256 amount) public returns (bool) {
        userBalances[owner][token] += amount;
        return true;
    }
}