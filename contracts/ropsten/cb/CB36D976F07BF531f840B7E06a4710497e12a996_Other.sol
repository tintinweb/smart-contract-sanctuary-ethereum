// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Other {
    uint public val;
    uint public otherVal;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 11111111;
    }

    function mult(uint a) public {
        val = 0;
        otherVal = a*111;
    }
}