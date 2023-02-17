// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import  "./strings.sol";

contract IPFS_FileStore {
    using strings for *;
    mapping(address => bool) public authorizedAddresses;
    mapping(bytes32 => mapping(string => string)) public storedHashes;
    event LogHashStored(bytes32[] blockchainHash, string[] ipfsHash);

    function authorize(address user) public {
        authorizedAddresses[user] = true;
    }

    function storeHash(string memory ipfsHash, string memory msgHash) public {
        require(authorizedAddresses[msg.sender], "Unauthorized");
        strings.slice memory ipfsHashSource = ipfsHash.toSlice();
        strings.slice memory delim = '-'.toSlice();
        string[] memory arrIpfsHash = new string[](ipfsHashSource.count(delim)+1);
        bytes32[] memory arrBlockchainHash = new bytes32[](ipfsHashSource.count(delim)+1);
        for(uint i = 0; i < arrIpfsHash.length; i++){
            string memory ipfs = ipfsHashSource.split(delim).toString();
            bytes32 blockchainHash = keccak256(abi.encodePacked(ipfs, msgHash));
            arrBlockchainHash[i] = blockchainHash;
            arrIpfsHash[i] = ipfs;
            storedHashes[blockchainHash][msgHash] = ipfs;
        } 
       
        emit LogHashStored(arrBlockchainHash, arrIpfsHash);
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