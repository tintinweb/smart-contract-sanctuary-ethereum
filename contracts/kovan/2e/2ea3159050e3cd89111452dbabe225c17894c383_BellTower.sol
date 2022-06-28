/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract BellTower {
    // counter of how many times the bell has been rung;
    uint public bellRung;

    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    // Ring the Bell
    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}