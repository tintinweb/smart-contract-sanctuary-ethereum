// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract KeyRegistry {
    struct Key {
        bytes32 sig;
        bytes32 enc;
    }

    error AlreadyRegistered();

    event PublicKeyRegistered(
        address indexed account,
        bytes32 sig,
        bytes32 enc
    );

    mapping(address => Key) public keys;

    function addPublicKey(bytes32 sig, bytes32 enc) public {
        if (keys[msg.sender].sig != 0x0 && keys[msg.sender].enc != 0x0)
            revert AlreadyRegistered();

        keys[msg.sender] = Key(sig, enc);
        emit PublicKeyRegistered(msg.sender, sig, enc);
    }

    function getPublicKey(address user) public view returns (Key memory) {
        return keys[user];
    }
}