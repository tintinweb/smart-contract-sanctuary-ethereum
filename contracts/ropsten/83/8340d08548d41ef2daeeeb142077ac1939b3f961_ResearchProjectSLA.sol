/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract ResearchProjectSLA {
    struct Record{
        bytes32 dateTime;
        bytes32 hashCode;
    }

    Record[] public records;
    function updateRecords(bytes32 _dateTime,bytes32 _hashCode) public {
        records.push(Record({
                dateTime: _dateTime,
                hashCode: _hashCode
            }));
    }

    function challenge() public view returns (Record memory){
        uint totalRecords = records.length;
        return records[totalRecords-1];
    }

    function challengeHash() public view returns (bytes32){
        uint totalRecords = records.length;
        return records[totalRecords-1].hashCode;
    }
}