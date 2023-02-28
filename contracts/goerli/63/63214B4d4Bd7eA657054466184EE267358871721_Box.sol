// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Box {
    uint256 internal length;
    uint256 internal width;
    uint256 internal height;

    constructor(
        uint256 l,
        uint256 w,
        uint256 h
    ) {
        length = l;
        width = w;
        height = h;
    }

    function volume() public view returns (uint256) {
        return length * width * height;
    }
}