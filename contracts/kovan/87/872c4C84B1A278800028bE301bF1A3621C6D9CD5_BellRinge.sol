/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BellRinge {


    uint public bellRinge;

    event BellRung(uint ringForTheNthTime,address from);

    function ringTheBell() public {

        bellRinge++;

        emit BellRung(bellRinge,msg.sender);
    }


}