//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


contract Token {
    uint256 public totalSupply;

    string public name = "MyToken";
    string public symbol = "MTK";

    address public owner;

    constructor(uint256 _totalSupply, address _owner) {
        totalSupply = _totalSupply;
        owner = _owner;
    }

}