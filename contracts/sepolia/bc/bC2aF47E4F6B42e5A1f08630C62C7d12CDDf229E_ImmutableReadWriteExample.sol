/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImmutableReadWriteExample {
    address immutable public owner;
    uint256 immutable public creationTime;
    uint256 public data;

    constructor(uint256 _data) {
        owner = msg.sender;
        creationTime = block.timestamp;
        data = _data;
    }

    function setData(uint256 _newData) external {
        require(msg.sender == owner, "Only the contract owner can modify the data.");
        require(data == 0, "Data can only be set once.");
        data = _newData;
    }
}