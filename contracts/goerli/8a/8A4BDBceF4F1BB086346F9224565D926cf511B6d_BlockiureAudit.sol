// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract BlockiureAudit {
     address public owner;

     struct HashInfo {
        uint blockNumber;
        uint blockTimestamp;
     }

     mapping (bytes32 => HashInfo) private hashes;

     modifier onlyOwner {
         require(msg.sender == owner, "Not allowed: only owner");
         _;
     }

     event NewHash(bytes32 indexed hash);

     constructor() {
         owner = msg.sender;
     }

     function addHash(bytes32 hash) public onlyOwner {
         require(hashes[hash].blockNumber == 0, "Hash already registered.");
         HashInfo memory newHashInfo = HashInfo(block.number, block.timestamp);
         hashes[hash] = newHashInfo;
         emit NewHash(hash);
     }

     function retrieveHash(bytes32 hash) public view returns(uint, uint) {
         return (hashes[hash].blockNumber, hashes[hash].blockTimestamp);
     }

     function transferOwnership(address newOwner) public onlyOwner{
         owner = newOwner;
     }
}