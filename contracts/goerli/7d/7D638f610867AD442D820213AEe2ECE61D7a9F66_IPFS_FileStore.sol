// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./strings.sol";
contract IPFS_FileStore {
    using strings for *;
    mapping(address => bool) public authorizedAddresses;
    mapping(bytes32 => mapping(string => string)) public storedHashes;
    event LogHashStored(bytes32[] blockchainHash, string[] arrResourceId);
    function authorize(address user) public {
        authorizedAddresses[user] = true;
    }
    function storeHash(string memory ipfsHash, string memory resourceHash, string memory resourceIds) public {
        require(authorizedAddresses[msg.sender], "Unauthorized");
        strings.slice memory ipfsHashSource = ipfsHash.toSlice();
        strings.slice memory resourceHashSource = resourceHash.toSlice();
        strings.slice memory resourceidsSource = resourceIds.toSlice();
        strings.slice memory delim = "-".toSlice();
        string[] memory arrIpfsHash = new string[](
            ipfsHashSource.count(delim) + 1
        );
        string[] memory arrResourceId = new string[](
            ipfsHashSource.count(delim) + 1
        );
        bytes32[] memory arrBlockchainHash = new bytes32[](
            ipfsHashSource.count(delim) + 1
        );
        for (uint256 i = 0; i < arrIpfsHash.length; i++) {
            string memory ipfs = ipfsHashSource.split(delim).toString();
            string memory rsrcHash = resourceHashSource.split(delim).toString();
            string memory resourceId = resourceidsSource.split(delim).toString();
            bytes32 blockchainHash = keccak256(abi.encodePacked(ipfs, rsrcHash));
            arrBlockchainHash[i] = blockchainHash;
            arrResourceId[i] = resourceId;
            storedHashes[blockchainHash][rsrcHash] = ipfs;
        }
        emit LogHashStored(arrBlockchainHash, arrResourceId);
    }

    function getHash(bytes32 blockchainHash, string memory resourceHash) public view returns (string memory)
    {
        return storedHashes[blockchainHash][resourceHash];
    }
    function isAuthorized(address user) public view returns (bool) {
        return authorizedAddresses[user];
    }
    function isHashStored(bytes32 blockchainHash, string memory resourceHash) public view returns (bool)
    {
        return (keccak256( abi.encodePacked(storedHashes[blockchainHash][resourceHash])) != keccak256(abi.encodePacked("")));
    }
}