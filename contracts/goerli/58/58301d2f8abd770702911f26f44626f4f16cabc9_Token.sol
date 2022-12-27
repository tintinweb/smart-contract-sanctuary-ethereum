/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

pragma solidity ^0.6.0;

contract Token {
    // Total supply of the token
    uint public totalSupply;

    // Mapping from owner address to balance
    mapping(address => uint) public balanceOf;

    // Event for token transfer
    event Transfer(address indexed from, address indexed to, uint value);

    // Constructor function to initialize the contract
    constructor() public {
        totalSupply = 1000000000;
        balanceOf[msg.sender] = totalSupply;
    }

    // Function to transfer tokens from one address to another
    function transfer(address _to, uint _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        totalSupply -= 1; // Burn 1 token
        emit Transfer(msg.sender, _to, _value);
    }
}