/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FileStoreIPFS {
    mapping(address => bool) public authorizedAddresses;
    mapping(bytes32 => mapping(string => string)) public storedOwnerHashes;
    mapping(bytes32 => mapping(address => string)) public storedHashes;

    event LogHashStored(
        bytes32 blockchainHash,
        string ipfsHash,
        string owner,
        address sender
    );

    function authorize(address user) public {
        authorizedAddresses[user] = true;
    }

    function storeHash(string memory ipfsHash, string memory owner) public {
        require(authorizedAddresses[msg.sender], "Unauthorized");
        bytes32 blockchainHash = keccak256(abi.encodePacked(ipfsHash, owner));
        if (bytes(owner).length > 0) {
            storedOwnerHashes[blockchainHash][owner] = ipfsHash;
        }
        storedHashes[blockchainHash][msg.sender] = ipfsHash;
        emit LogHashStored(blockchainHash, ipfsHash, owner, msg.sender);
    }

    function getHash(bytes32 blockchainHash, string memory owner)
        public
        view
        returns (string memory)
    {
        string memory result = "";
        if (bytes(owner).length > 0) {
            result = storedOwnerHashes[blockchainHash][owner];
        } else {
            result = storedHashes[blockchainHash][msg.sender];
        }
        return result;
    }

    function isAuthorized(address user) public view returns (bool) {
        return authorizedAddresses[user];
    }

    function isHashStored(bytes32 blockchainHash, string memory owner)
        public
        view
        returns (bool)
    {
        if (bytes(owner).length > 0) {
            return (keccak256(
                abi.encodePacked(storedOwnerHashes[blockchainHash][owner])
            ) != keccak256(abi.encodePacked("")));
        } else {
            return (keccak256(
                abi.encodePacked(storedHashes[blockchainHash][msg.sender])
            ) != keccak256(abi.encodePacked("")));
        }
    }
}