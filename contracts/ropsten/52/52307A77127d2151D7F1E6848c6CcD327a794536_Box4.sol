// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Box4 {
    uint public val;
    uint public otherVal;

    // function initialize(uint _val) external {
    //     val = _val;

    // }

    function inc() external {
        val += 1;
    }

    function mult(uint a) public {
        val = 333333;
        otherVal = a*33333;
    }
}