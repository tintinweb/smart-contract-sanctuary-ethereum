/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.7.0;

contract LPLToken {
    string public name = 'LPLToken';
    string public symbol = 'LPL';
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() public {
        totalSupply = 10000000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }
    
    function mint(address to, uint256 value) public {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
    
    function burn(address from, uint256 value) public {
        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }
    
    function transferFrom(address from, address to, uint256 value) public {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
    
    function totalTokenSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function tokenBalanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balanceOf[tokenOwner];
    }
}