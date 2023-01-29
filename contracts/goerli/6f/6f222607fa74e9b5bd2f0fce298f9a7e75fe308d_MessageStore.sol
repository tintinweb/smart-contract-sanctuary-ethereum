/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

/*
DESCRIPTION
This contract stores a data string (text)
It makes the stored data string available for anyone to read
*/

contract MessageStore {
    string private data;

    constructor (string memory initialData) {
        data = initialData;
    }

    function viewMessage() public view returns (string memory) {
        return data;
    }
}