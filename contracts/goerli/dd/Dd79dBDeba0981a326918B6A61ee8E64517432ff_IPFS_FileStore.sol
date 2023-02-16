/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IPFS_FileStore {
    mapping(address => bool) public authorizedAddresses;
    mapping(bytes32 => mapping(string => string)) public storedHashes;
    event LogHashStored(bytes32 blockchainHash, string ipfsHash);

    function authorize(address user) public {
        authorizedAddresses[user] = true;
    }

    function storeHash(string memory ipfsHash, string memory msgHash) public {
        require(authorizedAddresses[msg.sender], "Unauthorized");
        bytes32 blockchainHash = keccak256(abi.encodePacked(ipfsHash, msgHash));
        storedHashes[blockchainHash][msgHash] = ipfsHash;
        emit LogHashStored(blockchainHash, ipfsHash);
    }

    function getHash(bytes32 blockchainHash, string memory msgHash)
        public
        view
        returns (string memory)
    {
        return storedHashes[blockchainHash][msgHash];
    }

    function isAuthorized(address user) public view returns (bool) {
        return authorizedAddresses[user];
    }

    function isHashStored(bytes32 blockchainHash, string memory msgHash)
        public
        view
        returns (bool)
    {
        return (keccak256(
            abi.encodePacked(storedHashes[blockchainHash][msgHash])
        ) != keccak256(abi.encodePacked("")));
    }
}