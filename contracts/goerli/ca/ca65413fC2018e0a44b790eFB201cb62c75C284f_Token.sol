/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/Token.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Token  {

    // ESTADO GLOBAL
    uint256 public savedBalance; // 0
    uint256 public pricePerToken; // 
    uint256 public totalSupply;   

    // usuario => cantindad de tokens que posee
    mapping(address => uint256) public userBalances;

    modifier enoughBalance(
        address from, uint256 amount
    ) {
        require(userBalances[from] >= amount, "cantidad invalida");
        _;
    }

    constructor(uint256 _pricePerToken) {
        pricePerToken = _pricePerToken;
    }


    function buy(uint256 amount) public payable {
        require(msg.value >= amount * pricePerToken, "Incorrect value sent");
        savedBalance += msg.value;
        totalSupply += amount;
        userBalances[msg.sender] += amount;
    }

    function transfer(address from, address to, uint256 amount) public {
        _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) 
        internal 
        enoughBalance(from, amount)
    { 
        userBalances[from] -= amount;
        userBalances[to] += amount;    
    }


}