/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract trainning2 {

    uint Box = 1;

    function button1() public view returns(uint) {
        return Box;
    }

    function button2() public {
        Box = Box + 1;
    }
}