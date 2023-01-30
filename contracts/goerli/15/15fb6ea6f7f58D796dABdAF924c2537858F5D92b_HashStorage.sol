// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HashStorage {
    bytes32 public storedHash;

    function storeHash(
        string memory _name,
        string memory _surname,
        uint  _diplomano
        ) public {
        storedHash = keccak256(abi.encodePacked(_name, _surname, _diplomano));
    }
}