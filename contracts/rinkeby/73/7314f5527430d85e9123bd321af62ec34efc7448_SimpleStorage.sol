// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint favNumb;

    function store(uint newFavNumb) public {
        favNumb = newFavNumb;
    }

    function retreive() public view returns (uint) {
        return favNumb;
    }
}