// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Book {
    string name;
    uint256 pages;

    function initalize(string memory _name, uint256 _pages) public {
        name = _name;
        pages = _pages;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getPages() public view returns (uint256) {
        return pages;
    }
}