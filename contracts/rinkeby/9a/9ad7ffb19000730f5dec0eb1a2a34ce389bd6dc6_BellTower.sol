/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BellTower{

    uint public bellRung;

    event BellRung(uint rangForNthTime, address whoRangit);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}