/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract EtherWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only OWNER can call this function().");
        _;
    }
    
    receive() external payable {}

    function withdraw(uint amount) public payable onlyOwner {
       require(address(this).balance >= amount, "Insufficient Balance");
       payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}