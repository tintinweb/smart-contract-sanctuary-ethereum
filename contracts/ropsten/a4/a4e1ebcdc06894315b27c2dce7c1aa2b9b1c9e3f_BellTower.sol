/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract BellTower {
    // counter of how many times the bell been rung
    uint public bellRung;

    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRandit);

    function ringTheBell() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}