// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract BoxV3 {
    uint public value;
    uint public value1;
    uint public value3;

    // function initialze(uint val) external {
    //     value=val;
    // }

      function multiply() external {
        value1*=2;
    }

      function set() external {
        value3=20;
    }
}