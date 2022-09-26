/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4; 

contract BellTower {
    // Counter Of how many tines the bet L has been rung 
    uint public bellRung; 

    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    // Ring the bell
    function ringTheBe11() public { 
        bellRung++;

        emit BellRung(bellRung, msg.sender); 
    }
}