// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Multipayment {
    
    address private owner;
    uint total_value;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if the caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() payable{
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
        
        total_value = msg.value;
    }
    
    // function to change owner
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner; 
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    // charge enable the owner to store ether in the smart-contract
    function charge() payable public isOwner {
        total_value += msg.value;
    }
    
    // sum adds the different elements of the array and return its sum
    function sum(uint[] memory amounts) private returns (uint retVal) {
        uint totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        
        return totalAmnt;
    }
    
    // withdraw perform the transfering of ethers
    function withdraw(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }
    
    // multiple withdrawals in one
    function withdrawls(address payable[] memory addrs, uint[] memory amnts) payable public {
        total_value += msg.value;
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        // the value of the message in addition to stored value should be more than total amounts
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        
        for (uint i=0; i < addrs.length; i++) {
            total_value -= amnts[i];
            
            // send the specified amount to each recipient
            withdraw(addrs[i], amnts[i]);
        }
    }
    
}