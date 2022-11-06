/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorldComputer {
    string public title = "Quests";
    string public message = "Do 100 Things, Get Paid";

    uint8 numThings = 0;
    uint8 remNumThings = 100;
    uint funding = 0;

    function markTaskComplete() public {
        require(numThings <= 100, 'Quest completed');
        numThings += 1;
        remNumThings -= 1;
    }
    function getInfo() view public returns(uint8) {
        return numThings;
    }
}