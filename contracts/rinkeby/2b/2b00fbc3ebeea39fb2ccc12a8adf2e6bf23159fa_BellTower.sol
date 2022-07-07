/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BellTower {
    //counter of how many times the bell has been rung
    uint public bellRung;

    //Event to see ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    //ring the bell
    function ringTheBell() public{
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}