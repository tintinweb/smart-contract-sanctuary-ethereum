/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Token {
    mapping (address owner => uint) public balanceOf;
    mapping (address owner => mapping (address spender => uint)) public allowance;
    uint immutable public totalSupply;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed owner, address indexed spender, uint amount);

    error InvalidReceiver();

    constructor(uint amount) {
        balanceOf[msg.sender] = amount;
        totalSupply = amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function _transfer(address from, address to, uint amount) internal returns (bool) {
        if(from == address(0)) revert InvalidReceiver();
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }
}