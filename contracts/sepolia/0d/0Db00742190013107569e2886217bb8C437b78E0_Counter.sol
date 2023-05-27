// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counter {
    uint256 counter = 0;

    function IncreamentCounter() public {
        counter++;
    }
    function DecreamentCounter() public {
        counter--;
    }
    function SetCounter(uint256 __counter) public {
        counter = __counter;
    }
    function ReadCounter() public view returns(uint256) {
        return counter;
    }
}