/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BellTower {
    uint public counter = 0;

    // event

    event BellRung(uint rangForTheNthTime, address who);

    function ringTheBell() public {
        counter ++;
        emit BellRung(counter, msg.sender);
    }
}