/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;

contract EthWallet {
    address payable public owner;
    bool isOwner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not owner");
        _;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawal(uint256 _amount) public payable onlyOwner {
        require(msg.sender == owner, "Caller is not the owner");
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {} 
}