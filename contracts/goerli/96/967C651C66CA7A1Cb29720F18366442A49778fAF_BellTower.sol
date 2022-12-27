/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract TestContract{

}
//Some logic
contract BellTower{
    // counter for how many times the bell has ben rung
    //uint bellRung;
    uint public bellRung;

    // event for ring a bell
    event BellRung(uint rangForTheNthTime, address whoRangIt); 

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}