// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MakersApp {
    bytes32[] public creditedSources;
    mapping(bytes32 => string) public addressToSourceName;
    mapping(bytes32 => uint256) public idToIndex;
    mapping(bytes32 => bytes32) public hashToSource;
    address owner;

    modifier isOwner() {
        require(
            msg.sender == owner,
            "You are not the administrator - Not allowed to do this."
        );
        _;
    }
    modifier isSource() {
        require(idToIndex[hashAddress(msg.sender)] > 0, "Not a Source!");
        _;
    }

    // Assuring the correct ownability
    constructor() {
        owner = msg.sender;
        // Filling the 0th index of the list, for mapping purposes, with a dummy Id.
        creditedSources.push(0x000000000000000000000000000000000000000000); // Dummy Id
    }

    // The hashing could be done outside of the blockchain, 4real
    function hashText(string memory _text) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text));
    }

    function hashAddress(address _wallet) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_wallet));
    }

    // The Owner of the contract can append sources allowed to add data
    function addSource(string memory _name, address _wallet) public isOwner {
        bytes32 sourceId = hashAddress(_wallet);
        addressToSourceName[sourceId] = _name;
        creditedSources.push(sourceId);
        idToIndex[sourceId] = creditedSources.length;
    }

    // Only credited Sources are allowed to append information to the chain
    function addText(string memory _text) public isSource {
        bytes32 hashedText = hashText(_text);
        hashToSource[hashedText] = hashAddress(msg.sender); // Weird, but still operational...
    }

    // If the text has been appended by some truthful source, the hash was mapped before.
    function isFake(string memory _text) public view returns (bool) {
        if (hashToSource[hashText(_text)] > 0) return true;
        return false;
    }

    // Note to sELF: Gotta stop using the wallet as a private key
}