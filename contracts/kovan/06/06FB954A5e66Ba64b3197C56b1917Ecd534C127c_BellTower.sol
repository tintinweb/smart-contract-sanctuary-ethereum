/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.4;

contract BellTower {
    // Counter of how many times the bell has been rung
    uint public bellrung;
    
    //Event for ringing the bell
    event BellRung (uint RangForTheNthTime, address WhoRangIt);

    // Ring the bell 
    function RingTheBell () public {
        bellrung ++;

    emit BellRung(bellrung, msg.sender);
    }
}