/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract myContractForRopsten {
    string name;
    address public owner;
    mapping (address => uint) balances;
    
    constructor (string memory name_) {
        name = name_;
        owner = msg.sender;
    }

    function mint(address user, uint amount) public {
        uint balance = balances[user];
        balances[user] = balance + amount;
    }

    function getBalance(address user) view public returns (uint) {
        return balances[user];
    }

    function getOwnerAddress() view public returns (address) {
        return msg.sender;
    }

    function getOwnerBalance() view public returns (uint) {
        return balances[msg.sender];
    }

    function transfer(address _to, uint amount) public {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[_to] = balances[_to] + amount;
    }

}