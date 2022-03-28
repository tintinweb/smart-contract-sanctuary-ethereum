/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.8.4;

contract banque{
    mapping(address => uint) balance;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function addBalance(uint toAdd, address to) public returns (uint) {
        require(msg.sender == owner);
        balance[to] += toAdd;
        return balance[to];
    }
    function getBalance() public view returns (uint) {
       return balance[msg.sender];
    }
    function transfer(address from, address to, uint amount) public {
       require(balance[from] >= amount);
       balance[from] = balance[from] - amount;
       balance[to] += amount;
    }
}