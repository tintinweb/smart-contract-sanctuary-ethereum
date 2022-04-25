/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract TestContract {
// Some logic
}

contract BellTower{
    // counter for how many times the bell has been rung
    uint public bellRung;

    // event for ringing a bell
    event BellRung(uint rangFortheNthTime, address whoRangIt);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}