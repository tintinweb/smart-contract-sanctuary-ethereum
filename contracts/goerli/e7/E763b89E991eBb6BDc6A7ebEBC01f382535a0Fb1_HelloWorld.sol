// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract HelloWorld {
    string private _data;

    constructor(string memory data){
        _data = data;
    }

    function enterString(string memory data) external {
        _data = data;
    }

    function getStoredString() external view returns(string memory){
        return _data;
    }
}