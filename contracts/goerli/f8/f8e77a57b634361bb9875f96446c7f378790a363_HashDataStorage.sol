/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HashDataStorage {
    struct Data {
        bytes32 hashValue;
        uint256 carbonEmissions;
    }

    // Use serial number to find contract hash value and carbon emissions of contract.
    mapping(bytes32 => Data) public dataMap;
    
    function setData(bytes32 key, bytes32 value1, uint256 value2) public {
        dataMap[key] = Data(value1, value2);
    }
    
    function getData(bytes32 key) public view returns (bytes32, uint256) {
        return (dataMap[key].hashValue, dataMap[key].carbonEmissions);
    }
}