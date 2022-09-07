/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// Primary Author(s)
// Hassan Abbasi: https://github.com/mikoronjoo


pragma solidity ^0.8.16;


contract Registrar {

    struct Document {
        string title;
        address author;
        uint256 timestamp;
    }

    mapping(bytes32 => Document) public documents;

    event documentRegistered(bytes32 fileHash, string title, address author);
    event titleChanged(bytes32 fileHash, string newTitle);

    constructor() {
    }

    function getTimestamp(
        bytes32 hash_
        ) external view returns (uint256) {
            return documents[hash_].timestamp;
        }

    function getSigner(
        bytes32 hash_,
        string memory title,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes32 message = keccak256(abi.encodePacked(hash_, title));
        address signer = ecrecover(message, v, r, s);
        return signer;
    }

    function register(
        bytes32 hash_,
        string memory title,
        address author,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(documents[hash_].timestamp == 0, "Registrar.register :: hash is already registered");
        require(getSigner(hash_, title, v, r, s) == author, "Registrar.register :: author is not signer");
        documents[hash_] = Document(title, author, block.timestamp);
        emit documentRegistered(hash_, title, author);
    }

    function registerWithoutSign(
        bytes32 hash_,
        string memory title
    ) external {
        require(documents[hash_].timestamp == 0, "Registrar.registerWithoutSign :: hash is already registered");
        documents[hash_] = Document(title, msg.sender, block.timestamp);
        emit documentRegistered(hash_, title, msg.sender);
    }

    function updateTitle(
        bytes32 hash_,
        string memory newTitle
    ) external {
        require(documents[hash_].timestamp != 0, "Registrar.updateTitle :: hash is not found");
        require(documents[hash_].author == msg.sender, "Registrar.updateTitle :: sender is not author");
        documents[hash_].title = newTitle;
        emit titleChanged(hash_, newTitle);
    }
}

// Dar panah Khoda