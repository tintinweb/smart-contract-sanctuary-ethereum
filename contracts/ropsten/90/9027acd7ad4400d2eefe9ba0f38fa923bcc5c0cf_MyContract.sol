/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// Creating a contract 
contract MyContract 
{         
    // Private state variable 
    address private owner;
    
    // Defining a constructor    
    constructor() {    
        owner =  msg.sender;
    }

    // Function to get address of owner 
    function getOwner() public view returns (address) {     
        return owner; 
    }

    // Function to return current balance of owner 
    function getBalance() public view returns(uint256){ 
        return owner.balance; 
    } 

    event SendEther(uint senderBalance, uint receiverBalance);

    function transferEther(address payable receiverAdr) public payable {
        require(owner ==  msg.sender);
        receiverAdr.transfer(msg.value);
        emit SendEther(owner.balance, receiverAdr.balance);
    }
}