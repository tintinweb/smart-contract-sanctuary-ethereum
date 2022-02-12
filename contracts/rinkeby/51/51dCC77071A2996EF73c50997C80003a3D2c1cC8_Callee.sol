/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Callee {
    uint[] public values;

    function getValue(uint initial) public pure returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) public {
        values.push(value);
    }
    function getValues() public view returns(uint) {
        return values.length;
    }
}