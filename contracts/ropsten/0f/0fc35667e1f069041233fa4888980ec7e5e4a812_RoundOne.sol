/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RoundOne {

    bool public amIowner = true;
    ///this is not the owner
    ///error NotOwner();

    ///this is the owner
    ///error YouAreOwner();

    // owner is an address and a public variable
    address public owner;

    ///constructor {}
    ///(bytes32[] memory) 
    
        ///owner = msg.sender;
    
    // is msg.sender the ycontract owner?
    function flipOwner() public {
        amIowner =! amIowner;
    }
    
    ///function checkStatus() public {
      ///  require(amIowner, "You must be owner");
         
        
        ///if (owner != msg.sender) 
        ///revert NotOwner();
        ///if (owner == msg.sender)
        ///revert YouAreOwner();
 ///   }
}