/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract InheritanceModifierExample {

    mapping(address => uint) public tokenBalance;

    address owner;

    uint tokenPrice = 1 ether;

    constructor() {
        owner = msg.sender;
        tokenBalance[owner] = 100;
    }

    function createNewToken() public {
        require(msg.sender == owner, "You are not allowed");
        tokenBalance[owner]++;
    }

    function burnToken() public {
        require(msg.sender == owner, "You are not allowed");
        tokenBalance[owner]--;
    }

    function purchaseToken() public payable {
        require((tokenBalance[owner] * tokenPrice) / msg.value > 0, "not enough tokens");
        tokenBalance[owner] -= msg.value / tokenPrice;
        tokenBalance[msg.sender] += msg.value / tokenPrice;
    }

    function sendToken(address _to, uint _amount) public {
        require(tokenBalance[msg.sender] >= _amount, "Not enough tokens");
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
    }

}