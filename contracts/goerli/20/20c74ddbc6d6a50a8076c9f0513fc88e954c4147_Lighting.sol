/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Lighting {
    address public oracle;

    struct ElectricityRecord {
        uint256 consumed;
        uint256 produced;
        uint256 date;
    }

    mapping(uint256 => mapping(uint256 => ElectricityRecord))
        public electricalRecords;
    mapping(uint256 => ElectricityRecord[]) public last10EntityRecords;
    //mapping(uint256 => ElectricityRecord[]) public last10Records;
    ElectricityRecord[] public last10Records;

    function getProducedRecord(uint256 producerId, uint256 dateInEpoch)
        external
        view
        returns (uint256)
    {
        return electricalRecords[producerId][dateInEpoch].produced;
    }

    function getConsumedRecord(uint256 producerId, uint256 dateInEpoch)
        external
        view
        returns (uint256)
    {
        return electricalRecords[producerId][dateInEpoch].consumed;
    }

    function getCompanyRecord(uint256 producerId, uint256 dateInEpoch)
        external
        view
        returns (ElectricityRecord memory)
    {
        return electricalRecords[producerId][dateInEpoch];
    }

    function getlast10Records() public view returns (ElectricityRecord[] memory) {
        return last10Records;
    }

    function getEntityLast10Records(uint256 producerId)
        external
        view
        returns (ElectricityRecord[] memory)
    {
        return last10EntityRecords[producerId];
    }

    function addRecord(
        uint256 producerId,
        uint256 epochDate,
        ElectricityRecord calldata record
    ) external {
        if (last10EntityRecords[producerId].length == 10) {
            last10EntityRecords[producerId].pop();
        }
        electricalRecords[producerId][epochDate] = record;
        last10EntityRecords[producerId].push(record);
    }
}