/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

//SPDX-License-Identifier: UNLICENSED
// test.bin = bytecode
// test.abi = abi

pragma solidity ^0.8.17;

contract test {
    int256 _multiplier;
    // index only runs when the specified variable matches
    event multiplied(int256 indexed val, address indexed sender, int256 result);

    constructor(int256 multiplier) {
        _multiplier = multiplier;
    }

    // SendTransactionAsync()
    function multiplyWithEvent(int256 val) public payable returns (int256 result) {
        result = val * _multiplier;
        emit multiplied(val, msg.sender, result);
        return result;
    }

    // CallAsync()
    function multiplyWithoutEvent(int256 val) public view returns (int256 result) {
        result = val * _multiplier;
        return result;
    }
}