/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract HashStorage {


    event project(
        bytes32 finalHash,
        bytes32 allfilesHash,
        string cid,
        address user,
        uint256 date,
        bytes32[] hashes,
        uint256 numberoffiles
    );

    
    function addProject(
        bytes32[] memory hashes,
        string memory cid
    ) public returns (bytes32) {

        require(bytes(cid).length != 0, "cid must not be empty");


        bytes32 allfilesHash = keccak256(abi.encodePacked(hashes));
        bytes32 finalHash = keccak256(abi.encodePacked(cid, allfilesHash));

        address user = msg.sender;
        uint256 date = block.timestamp;
        uint256 numberoffiles = hashes.length;

        emit project(finalHash, allfilesHash, cid, user, date, hashes, numberoffiles);

        return finalHash;
    }
}