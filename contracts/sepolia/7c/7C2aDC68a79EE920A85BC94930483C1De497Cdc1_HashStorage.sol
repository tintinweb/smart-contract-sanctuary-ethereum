/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

contract HashStorage {
    // uint public counter;
    mapping(string => uint) hashedContractsToIds;

    function setHashedValues(string memory hashedContract) external returns (uint) {
        // counter++;
        uint timestamp = block.timestamp;
        hashedContractsToIds[hashedContract] = timestamp;
        return timestamp;
    }

    function getIdByHashedContract(string memory hashedContract) external view returns (uint) {
        return hashedContractsToIds[hashedContract];
    }
}