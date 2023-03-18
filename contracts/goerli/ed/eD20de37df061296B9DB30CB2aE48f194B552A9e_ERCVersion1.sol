// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ERCVersion1 {
    bool private lock;
    address private owner;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint value);

    function start(uint amount) external {
        symbol = "HT";
        name = "Haris Tokens";
        decimals = 18;
        owner = msg.sender;
        mintTokens(amount);
    }

    function mintTokens(uint _amount) public {
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }
}