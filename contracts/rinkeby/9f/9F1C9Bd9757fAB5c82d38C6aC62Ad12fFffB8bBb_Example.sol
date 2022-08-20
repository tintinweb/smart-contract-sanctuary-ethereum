// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Example {
    string password;

    function setPassword(string memory _password) public {
        password = _password;
    }

    function checkPassword(string memory _password) public view returns(bool) {
        if (keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(password))) {
            return true;
        }
        return false;
    }
}