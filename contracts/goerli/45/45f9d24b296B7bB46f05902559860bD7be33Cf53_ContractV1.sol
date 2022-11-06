// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ContractV1 {
    uint public value;

    function initialize(uint _value) external {
        value = _value;
    }
}