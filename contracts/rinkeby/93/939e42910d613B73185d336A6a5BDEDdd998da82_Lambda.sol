// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lambda {

    string public name = "Initial";

    function changeName(string memory _newName) public {
        name = _newName;
    }
}