// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Notato {
    event DocumentHash(bytes32 documentHash);

    function addHash(bytes32 _documentHash) public {
        emit DocumentHash(_documentHash);
    }
}