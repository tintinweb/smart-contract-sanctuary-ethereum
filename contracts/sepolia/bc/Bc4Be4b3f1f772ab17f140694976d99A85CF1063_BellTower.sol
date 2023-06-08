/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract BellTower {
    // Counter how many times the bell has been rung 
    uint public bellRung;

    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    // Ring the bell
    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}