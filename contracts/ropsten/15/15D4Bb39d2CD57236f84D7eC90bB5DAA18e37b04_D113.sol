/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

contract D113 {

    string public name;
    uint256 public totalSupply;
    uint256 public decimals;
    string public symbol;
    address public owner;

    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);


    constructor() {
        name = 'D113';
        totalSupply = 1000000000000000000000000000;
        decimals = 18;
        symbol = 'D113';
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        balance[owner] = totalSupply;
    }

    function transfer(address to, uint amount) public returns (bool success) {
        require(msg.sender == owner, "Only owner can transfer tokens");
        require(balance[msg.sender] >= amount);
        unchecked{balance[msg.sender] -= amount;}
        unchecked{balance[to] += amount;}
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool success) {
        require(amount<=balance[msg.sender]);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        require(amount <= allowance[from][msg.sender]);
        unchecked{balance[from] -= amount;}
        unchecked{allowance[from][msg.sender] -= amount;}
        unchecked{balance[to] += amount;}
        emit Transfer(from, to, amount);
        return true;
    }

    function newOwner(address _newOwner) public virtual {
        require(msg.sender == owner, "You are not the owner");
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransfer(owner, _newOwner);
        owner = _newOwner;
    }




}