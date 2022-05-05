/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.7.0 < 0.9.0;
 
contract main{
 
    address payable public owner_addr;
    
    struct member {
        string name;
        address payable addr;
        uint256 balance;
        bool is_member;
    }
 
    mapping(address => member) addr2member;
 
    constructor(address payable addr) {
        owner_addr = addr;
    }
 
    function register(string memory name, address payable addr) public {
        addr2member[addr].name = name;
        addr2member[addr].addr = addr;
        addr2member[addr].balance = 0;
        addr2member[addr].is_member = true;
    }
 
    function deposit() public payable{
        require(addr2member[msg.sender].is_member == true, "You are not a member yet.");
        addr2member[msg.sender].balance += msg.value;
    }
 
    function withdrow(uint256 amount) public {
        require(addr2member[msg.sender].is_member == true, "You are not a member yet.");
        require(addr2member[msg.sender].balance >= amount, "The value is invalid.");
        addr2member[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
    }
 
    function takeview() public view returns(string memory, address payable, uint256) {
        require(addr2member[msg.sender].is_member == true, "You are not a member yet.");
        return (addr2member[msg.sender].name, addr2member[msg.sender].addr, addr2member[msg.sender].balance);
    }
}