// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract HashStorer {
    mapping(bytes32 => uint) hashes;

    event StoredNewHash(bytes32 hash, uint256 block);
    error PreviouslyStored(bytes32 hash, uint256 block);
    error NotFound(string content);

    constructor() {}

    function store(bytes32 _hash) external returns (uint256) {
        if (hashes[_hash] > 0) {
            revert PreviouslyStored(_hash, hashes[_hash]);
        }

        hashes[_hash] = block.number;
        emit StoredNewHash(_hash, block.number);

        return block.number;
    }

    function query(string memory _content) external view returns (uint256) {
        uint256 storedInBlock = hashes[keccak256(abi.encodePacked(_content))];

        if (storedInBlock == 0) {
            revert NotFound(_content);
        }

        return storedInBlock;
    }
}