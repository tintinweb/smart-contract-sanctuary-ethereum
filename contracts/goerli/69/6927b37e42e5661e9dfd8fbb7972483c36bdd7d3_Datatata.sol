// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Datatata {
    uint private _currentData;

    constructor() {
    }

    function data() public view returns (uint) {
        return _currentData;
    }

    function setData(uint v) public {
        _currentData = v;
    }
}