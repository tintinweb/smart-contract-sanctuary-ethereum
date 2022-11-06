// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ContractV2 {
    uint public value;

    function sum(uint _value) external {
        value += _value;
    }
}