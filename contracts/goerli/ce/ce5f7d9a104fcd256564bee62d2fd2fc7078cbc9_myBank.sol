/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract myBank {
address owner;
constructor() {
owner = msg.sender;
}
modifier onlyOwner() {
require(msg.sender == owner);
_;
}
struct client {
string name;
uint256 contactNumber;
uint256 balance;
}
mapping(address => client) public clients;
function addNewClient(string memory _name, uint256 _contactNo)
public onlyOwner
{
clients[msg.sender].name = _name;
clients[msg.sender].contactNumber = _contactNo;
clients[msg.sender].balance = 0;
}
function getClientBalance() public view returns (uint256) {
return (clients[msg.sender].balance);
}
function recieveFunds() public payable {
clients[msg.sender].balance += msg.value;
}
function withdraw(uint256 _amount) public onlyOwner returns (uint256) {
if (_amount <= clients[msg.sender].balance) {
clients[msg.sender].balance -= _amount;
} return clients[msg.sender].balance;
}
}