/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11; 

contract TransferToken { 
    mapping(address => uint256) public balanceOf;
    string public name; 
    string public symbol; 
    uint256 public decimals; 
    uint256 public totalSupply; 

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) { 
        name = _name; 
        symbol = _symbol; 
        decimals = _decimals; 
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply; 
    } 

    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}