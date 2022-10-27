// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Counter {

    uint256 testCounter;

    function incrementCounter() public {
        testCounter++;
    }

    function seeCounter() public view returns(uint256) {
        return testCounter;
    }
}