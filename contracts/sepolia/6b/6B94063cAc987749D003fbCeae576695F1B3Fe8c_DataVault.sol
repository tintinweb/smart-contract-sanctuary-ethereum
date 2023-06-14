/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DataVault {
    mapping(string => string) internal _data;

    constructor() {}

    function setVal(string memory key, string memory val) public {
        _data[key] = val;
    }

    function getVal(string memory key) public view returns(string memory) {
        return _data[key];
    }

    function deleteVal(string memory key) public {
        delete _data[key];
    }
}