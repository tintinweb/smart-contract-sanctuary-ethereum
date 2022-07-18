/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SLAEnsurer
 * @dev To ensure SLA for peers
 */
contract SLAEnsurer {
    struct Record{
        bytes32 dateTime;
        bytes32 hashCode;
    }

    Record[] public records;
    function updateRecords(bytes32 newDateTime,bytes32 newHashCode) public {
        records.push(Record({
                dateTime: newDateTime,
                hashCode: newHashCode
            }));
    }

    function challenge() public view returns (Record memory){
        uint totalRecords = records.length;
        return records[totalRecords-1];
    }
}