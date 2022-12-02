// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract StoreContract {
    uint256 number;

    function store(uint256 _num) public {
        number = _num;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}