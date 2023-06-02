// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleContract {
    uint256 number;
    string public name;

    function setNumber(uint256 _newNumber) public {
        number = _newNumber;
    }

    function setName(string memory _newName) public {
        name = _newName;
    }
}