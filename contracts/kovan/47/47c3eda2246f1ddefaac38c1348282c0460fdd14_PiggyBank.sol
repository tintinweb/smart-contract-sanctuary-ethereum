/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract PiggyBank{
    uint public goal;    
    address payable owner;
    address payable sender;
    constructor(uint _goal){
        goal = _goal;
        owner = payable(msg.sender);
    }
    receive() external payable{   
        //if(payable(msg.sender) == owner){
        //    withdraw();     
        //}
        //withdraw();     
        sender = payable(msg.sender);
    }     
    
    modifier onlyOwner{         
        require(
            owner == payable(msg.sender), 
            "only owner can take money"
        );
        _;
    }

    function getMyBalance()  public view returns(uint){
        return address(this).balance;
    }
    function getOwnerAddress() public view returns(address){ return owner; }
    function getSenderAddress() public view returns(address){ return sender; }

    function takeMoney(uint want) onlyOwner public returns (bool) {      
        payable(msg.sender).transfer(want);
        return true;
    }
    function withdraw() onlyOwner public{
        if(getMyBalance() >= goal){        
            selfdestruct(payable(msg.sender));
        }
    }
}