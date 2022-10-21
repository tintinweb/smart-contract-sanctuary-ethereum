// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract myContractV2 {
    uint public value;

    // function initialize(uint _value) external {
    //     value = value;
    // }

    function inc() external {
        value += 1;
    }

    function dubt() external {
        value -= 1;
    }
}