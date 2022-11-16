/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract week_counter {
    address public owner;
    int public week;

    constructor(){
        owner = msg.sender;
    }

    function show_week() public view returns (int) {
        return week;
    }

    function set_week(int _week) public {
        week = _week;
    }

}