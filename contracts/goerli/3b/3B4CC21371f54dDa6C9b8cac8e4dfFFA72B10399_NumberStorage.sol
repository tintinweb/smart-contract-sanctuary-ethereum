// SPDX-License-Identifier: dvdch.eth

pragma solidity ^0.8.10;

contract NumberStorage {
    uint256 private _number;

    function setNumber(uint256 value) external {
        _number = value;
    }

    function number() public view returns(uint256) {
        return _number;
    }
}