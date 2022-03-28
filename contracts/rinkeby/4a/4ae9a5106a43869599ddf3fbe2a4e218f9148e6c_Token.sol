/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf; // Key/Value, key = address, value = balance => How many tokens each has
    mapping(address => mapping(address => uint256)) public allowance;  // Two dimensional array

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // When smart contract is created or deployed the project
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        // key= msg.sender, value= totalSupply
        balanceOf[msg.sender] = totalSupply; // This will assign the value/balance to the person who is deploying the contract
        emit Transfer(address(0), msg.sender, _totalSupply);  // Creating zero blocks with 0x0000 address at first
    }

    // Move token from one account to another
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // transfer by approved person from original address of an amount within approved limit
    // _from, address sending to and the amount to send
    // _to receiver of token
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}