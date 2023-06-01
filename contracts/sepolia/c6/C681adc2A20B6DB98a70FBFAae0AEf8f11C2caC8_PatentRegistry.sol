/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

pragma solidity ^0.8.0;

contract PatentRegistry {
    struct Patent {
        address author;
        string owner;
        uint256 timestamp;
        string fileName;
    }

    mapping (bytes32 => Patent) private patents;
    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    function registerPatent(bytes32 patentHash, string memory owner, string memory fileName) public {
        require(msg.sender == contractOwner, "Only the contract owner can register patents.");
        require(patents[patentHash].author == address(0), "Patent with the same hash already exists.");

        Patent storage newPatent = patents[patentHash];
        newPatent.author = msg.sender;
        newPatent.owner = owner;
        newPatent.timestamp = block.timestamp;
        newPatent.fileName = fileName;
    }

    function verifyPatent(bytes32 patentHash) public view returns(bool, address, string memory, uint256, string memory) {
        Patent memory patent = patents[patentHash];
        return (patent.author != address(0), patent.author, patent.owner, patent.timestamp, patent.fileName);
    }
}