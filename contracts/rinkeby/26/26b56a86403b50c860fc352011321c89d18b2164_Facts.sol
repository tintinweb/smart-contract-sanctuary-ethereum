/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Facts {
    address owner;
    bool paused = false;
    uint minAmount = 0.01 ether;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Contracts aren't allowed to interact with this method");
        _;
    }

    event MintFact(address from, uint amount, uint256 timestamp);

    function generateFact() payable public isUser {
        require(!paused, "This contract is currently paused");
        require (msg.value >= minAmount, "Not enough ETH sent for the transaction");
        
        uint refund = msg.value - minAmount; 

        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        emit MintFact(msg.sender, msg.value, block.timestamp);
    }

    function setOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function setPaused(bool value) public isOwner {
        paused = value;
    }

    function withdraw(address payable wallet, uint amount) public isOwner {
        require(amount >= address(this).balance, "Withdraw amount is greater that contract balance");
        wallet.transfer(amount);
    }

    function isWalletOwner() public view returns (bool) {
        if(msg.sender == owner) {
            return true;
        }
        return false;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }
}