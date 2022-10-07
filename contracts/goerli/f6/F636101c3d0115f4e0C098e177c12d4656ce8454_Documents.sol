// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

pragma solidity 0.8.7;

contract Documents {

    address private owner;
    uint256 public idCounter;
    mapping(uint256 => bytes32) public documents;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    event CreateDocument(uint256 id);

    constructor() {
        owner = msg.sender;
        idCounter = 0;
    }

    function addDocument(string memory documentInfo) public isOwner returns (uint256) {
        idCounter++;
        documents[idCounter] = keccak256(abi.encodePacked(documentInfo));
        emit CreateDocument(idCounter);
        return idCounter;
    }

    function checkDocument(uint256 _idCounter, string memory documentInfo) public view returns (bool) {
        bool res = documents[_idCounter] == keccak256(abi.encodePacked(documentInfo));
        return res;
    }

}