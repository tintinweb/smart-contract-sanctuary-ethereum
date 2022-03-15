/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Events{
    event logData(uint id, string  data);
    event logDataIndexed(uint indexed id, string  data);
    event logUnused(uint id);
    event logUnusedIndexed(uint indexed id);
    event logDataAnonym(uint id, string  data)anonymous;
    event logDataAnonymIndexed(uint indexed id, string  data)anonymous;

    function log(uint _id, string calldata  _data) external {
        emit logData(_id, _data);
    }

    function logIndexed(uint _id, string calldata  _data) external {
        emit logDataIndexed(_id, _data);
    }

    function Unused(uint _id, string calldata  _data) external {
        emit logUnused(_id);
    }

    function UnusedIndexed(uint _id, string calldata  _data) external {
        emit logUnusedIndexed(_id);
    }

    function logAnonym(uint _id, string calldata  _data) external {
        emit logDataAnonym(_id, _data);
    }

    function logAnonymIndexed(uint _id, string calldata  _data) external {
        emit logDataAnonymIndexed(_id, _data);
    }
}