/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TimeStampHash
 * @dev 
 */
 contract TimeStampHash{
     struct Timestamp{
         uint totalStamps;
         mapping(bytes32 => bytes32) stamps;
     }

     mapping(address => Timestamp) public data;

    function insertTimeStamp(bytes32 stampHash, bytes32 nameHash) public {
        uint256 total = data[msg.sender].totalStamps;
        data[msg.sender].totalStamps = total + 1;
        data[msg.sender].stamps[nameHash] = stampHash;
    }

    function getTimeStamp(bytes32 nameHash) public view returns(bytes32 stampHash){
        return data[msg.sender].stamps[nameHash]; 
    }

 }