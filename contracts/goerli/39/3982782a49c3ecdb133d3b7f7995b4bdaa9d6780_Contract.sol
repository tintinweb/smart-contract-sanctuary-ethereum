// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    uint public record;

    constructor() public {
        record = 10;
    } 

    function changeRecord(uint _newRecord) public {
        record = _newRecord;
    }

    function getRecord() public returns(uint) {
        return record;
    }

}