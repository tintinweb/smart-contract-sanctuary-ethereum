// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PublicKeyRegistry {
    error AlreadyRegistered();

    event PublicKeyRegistered(address indexed account, bytes32 publicKey);

    mapping(address => bytes32) public publicKeys;

    function addPublicKey(bytes32 key) public {
        if (publicKeys[msg.sender] != bytes32(0)) revert AlreadyRegistered();
        publicKeys[msg.sender] = key;
        emit PublicKeyRegistered(msg.sender, key);
    }

    function getPublicKey(address user) public view returns (bytes32) {
        return publicKeys[user];
    }
}