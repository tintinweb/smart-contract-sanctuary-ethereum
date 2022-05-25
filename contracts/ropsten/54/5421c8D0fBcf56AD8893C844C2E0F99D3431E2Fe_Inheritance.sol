/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Inheritance {
    mapping (string => uint) balances;

    function setInheritance(string memory _name, uint amount) public {
        balances[_name] = amount;
    }

    function getAmount(string memory _name) public view returns (uint) {
        return balances[_name];
    }
}