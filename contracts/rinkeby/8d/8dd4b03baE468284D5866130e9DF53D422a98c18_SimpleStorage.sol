// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SimpleStorage {
    uint256 number;

    function store(uint256 _number) public virtual {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}