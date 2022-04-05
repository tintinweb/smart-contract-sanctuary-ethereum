//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    uint private counter;

    function countMe() external {
        counter += 1;
    }

    function currentCount() public view returns (uint) {
        return counter;
    }
}