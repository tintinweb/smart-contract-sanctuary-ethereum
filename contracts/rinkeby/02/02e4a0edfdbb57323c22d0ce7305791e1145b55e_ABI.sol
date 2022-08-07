// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ABI {
    bytes32 public stored;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function fromMemory(string memory _response) public pure returns (bytes32) {
        return keccak256(abi.encode(_response));
    }

    function store(string calldata _response) public {
        require(msg.sender == owner);
        stored = keccak256(abi.encode(_response));
    }

    function test(string memory _response) public view returns (bool) {
        return stored == keccak256(abi.encode(_response));
    }
}