// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bk {
    string public name;
    uint256 public pages;

    function initialize(string memory _name, uint256 _pages) public {
        name = _name;
        pages = _pages;
    }
}