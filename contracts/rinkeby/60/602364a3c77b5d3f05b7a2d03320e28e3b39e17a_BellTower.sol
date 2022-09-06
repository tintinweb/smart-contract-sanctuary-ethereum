/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BellTower {
    // Counter of how many times the bell has rung
    uint public bellRung;

    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    // Ring the bell
    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}