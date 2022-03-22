// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract AgeV2 {
    uint public myAge;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function ageIncrease() external {
        myAge += 1;
    }

}