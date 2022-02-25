/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Wallet {
    address payable public owner;

    event Deposit(address sender, uint amount, uint balance);
    event Withdraw(uint amount, uint balance);
    event Transfer(address to, uint amount, uint balance);

    modifier onlyOwner() {
        require (msg.sender == owner, "Not owner");
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function getBlanace() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
        emit Withdraw(_amount, address(this).balance);
    }
    
    function transferTo(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
        emit Transfer(_to, _amount, address(this).balance);
    }
}