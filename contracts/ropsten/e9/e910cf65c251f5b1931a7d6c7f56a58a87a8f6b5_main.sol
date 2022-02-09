/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract main {
    
    string owner_name;
    address payable owner_addr;
    struct member {
        string name;
        address payable addr;
        uint256 balance;
        bool ismem;
        uint256 time;
    }

    mapping(address => member) public addr2mem;
    
    constructor(string memory name, address payable addr) {
        owner_name = name;
        owner_addr = addr;
    }

    function signup(string memory name, address payable addr) public  {
        addr2mem[addr].name = name;
        addr2mem[addr].addr = addr;
        addr2mem[addr].balance = 0;
        addr2mem[addr].ismem = true;
        addr2mem[addr].time = block.timestamp;
    }

    function deposit() public payable {
        require(addr2mem[msg.sender].ismem);
        require(checktime());
        addr2mem[msg.sender].balance += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(addr2mem[msg.sender].balance >= amount);
        addr2mem[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    fallback() external payable{}
    receive() external payable{}

    function destruct() public  {
        require(msg.sender == owner_addr);
        selfdestruct(owner_addr);
    }

    function checktime() public view returns(bool) {
        require(block.timestamp - addr2mem[msg.sender].time > 10);
        return true;
    }

}