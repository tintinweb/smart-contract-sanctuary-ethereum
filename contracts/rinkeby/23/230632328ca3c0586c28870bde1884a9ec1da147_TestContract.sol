/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TestContract {
    uint testVal;

    function show() public view returns (uint) {
        return testVal;
    }

    function addition() public {
        testVal += 1;
    }

    function multiplication(uint argVal) public {
        testVal *= argVal;
    }
}