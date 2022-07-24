// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BoxV3 {
    uint public val;
    uint public otherVal;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }

    function mult(uint a) public {
        val = val + a;
        otherVal = a*1000;
    }
}