//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract Attendance {
    //mapping (address=>uint) attendees;
    uint public numberAttending = 0;
    
    //uint public mybal;
 function IM_HERE( ) public payable { 
        
      //attendees[msg.sender] = msg.value;
      numberAttending++;
     // mybal = address(this).balance;
    }
}