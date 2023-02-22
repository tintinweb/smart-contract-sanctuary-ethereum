//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleCoin{

    string public name = "Nossa Coin";
    string public symbol = "NSC";
    uint public totalSupply = 100_010;

    address public owner;
    
    mapping(address => uint256) public balanceOf;

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}