/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.24;

//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PeazeSplit {
    function pullFunds(address consumer, uint amount) external {
        ERC20Interface c = ERC20Interface(consumer);
        require(address(c).balance >= 1, "Insufficient Funds");
        c.approve(address(this), amount);
        c.transferFrom(consumer, address(this), amount);
    }
}