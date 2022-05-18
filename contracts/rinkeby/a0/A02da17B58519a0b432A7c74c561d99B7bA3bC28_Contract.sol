// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contract {
    constructor() {}
    string text;
    function double(uint256 _numero) external pure returns (uint256) {
        return _numero * 2;
    }

    function set(string memory _text) public{
    text=_text;
    }

    function get() public view returns(string memory)
    {
        return text;
    }
}