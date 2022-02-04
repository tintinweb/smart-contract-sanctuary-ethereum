// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract BoxV2 {
  uint public value;
    uint public value1;

    // function initialze(uint val) external {
    //     value=val;
    // }

      function inc() external {
        value1+=1;
    }

      function dec() external {
        value-=1;
    }

}