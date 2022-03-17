/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BlueSurgeToken {

    // My Variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    uint256 private price = 1000;

    // Keep track balances and allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events - fire events on state changes etc
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "BlueSurgeToken";
        symbol = "BST";
        decimals = 18;
        totalSupply = 1000000; 
        balanceOf[msg.sender] = totalSupply;
    }
 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function buyToken(address _reciever, uint256 _value) external payable returns (bool success) {
        require(balanceOf[msg.sender] >= _value*price);
        balanceOf[_reciever] = balanceOf[_reciever] + (_value*price);
        _transfer(msg.sender, _reciever, _value*price);
        return true;
    }

    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
}