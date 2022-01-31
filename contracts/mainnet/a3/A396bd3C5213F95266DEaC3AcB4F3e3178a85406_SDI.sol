// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SDI {

    address owner;
    mapping (address => uint) accounts;

    constructor()  {
        owner = msg.sender;
    }

    function mint(address recipient, uint value) public {
        if(msg.sender == owner) {
            accounts[recipient] += value;
        }
    }

    function transfer(address to, uint value)  public{
        if(accounts[msg.sender] >= value) {
            accounts[msg.sender] -= value;
            accounts[to] += value;
        }
    }

    function balance(address addr) public view returns (uint) {
        return accounts[addr];
    }
}