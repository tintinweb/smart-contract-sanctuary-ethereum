/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Add {
    uint value;

    function setValue(uint a) public returns (uint) {
        value = a;
        return value;
    }

    function getValue() public view returns (uint) {
        return value;
    }

    function add(uint8 a, uint8 b) public pure returns (uint8) {
        return a + b;
    }

    function getCallData(uint8 a, uint8 b) public pure returns (bytes memory) {
        return abi.encodeWithSelector(this.add.selector, a, b);
    }
}