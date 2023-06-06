/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

//SPDX-License-Identifier: MIT

// This is a basic contract for understanding Deposit/Withdraw/checkBalance.

pragma solidity ^0.8.0;

contract DogHappyBank {
    
    mapping(address => uint) _balances;
    event Deposit(address indexed owners, uint amount);
    event Withdraw(address indexed owners, uint amount);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Shelter can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero !!!");

        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

 function withdraw() onlyOwner public {
        payable(owner).transfer(address(this).balance);
    }

    function balance() public view returns(uint) {
        return _balances[msg.sender];
    }

    function balanceOf(address owners) public view returns(uint) {
        return _balances[owners];
    }
}