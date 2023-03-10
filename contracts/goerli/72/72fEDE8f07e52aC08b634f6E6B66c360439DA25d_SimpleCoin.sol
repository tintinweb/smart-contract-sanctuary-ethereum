//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleCoin {

    string public name = "Nossa Coin";
    string public symbol = "NSC";
    uint public totalSupply = 100_001;

    mapping(address => uint) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _amount) public {
        balanceOf[msg.sender] = balanceOf[msg.sender] - _amount;
        balanceOf[_to] += _amount;
    }

}