/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Callee {
    uint[] public values;

    function getValue(uint initial) public returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) public {
        values.push(value);
    }
    function getValues() public view returns(uint) {
        return values.length;
    }
}