// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Counter {
    uint256 number;

    function updateNumber(uint256 _newNumber) public {
        number = _newNumber;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}