/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BellTower {
    uint public bellRung;

    // event for ringing a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}