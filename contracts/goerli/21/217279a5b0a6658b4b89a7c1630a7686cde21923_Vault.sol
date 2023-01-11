/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Vault {
    // slot 0
    uint256 private password;
    constructor(uint256  _password) {
        password = _password;
        User memory user = User({id: 0, password: bytes32(_password)});
        users.push(user);
        idToUser[0] = user;
    }

    struct User {
        uint id;
        bytes32 password;
    }

    // slot 1
    User[] public users;
    // slot 2
    mapping(uint => User) public idToUser; 
    function getArrayLocation(
        uint slot,
        uint index,
        uint elementSize
    ) public pure returns (bytes32) {
        uint256 a= uint(keccak256(abi.encodePacked(slot))) + (index * elementSize);
        return bytes32(a);
    }
}