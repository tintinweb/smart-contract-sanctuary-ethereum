/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
   /**
    * @dev Throws if called by any account other than the owner.
    */ 
   modifier onlyOwner(){
        require(msg.sender == owner, 'Can be called by owner only');
        _;
    }
 
   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */ 
   function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0), 'Wrong new owner address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Platinum Order
 * @dev Transfers eths as txn cost to account that will make "transfer" transaction.
 */
contract PlatinumOrder is Ownable{
    // Address to transfer ether to
    address payable public companyAddress = payable(address(0));

    event Order(address indexed from, uint indexed orderId, uint value);

    constructor(){
        owner = msg.sender;
        companyAddress = payable(msg.sender);
    }

    /** 
     * @dev Transfer received ether to company address and emit the event.
     * @param orderId New company address
     */
    function order(uint orderId) public payable{
        require(msg.sender != companyAddress, 'Unable to pay order to the same address as eth payee');
        
        if(msg.value > 0){
            companyAddress.transfer(address(this).balance);
        }

        emit Order(msg.sender, orderId, msg.value);
    }
  
    /** 
     * @dev Change company address.
     * @param _addr New company address
     */
    function setCompanyAddress(address payable _addr) onlyOwner public{
        companyAddress = _addr;
    }
}