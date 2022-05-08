// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Using byte32 in --constructor-args with forge create

contract Foo {
    address private immutable x;
    bytes32 private immutable y;
    uint256 private immutable z;
    address private immutable w;

    constructor(
        address _x,
        bytes32 _y,
        uint256 _z,
        address _w
    ) {
        x = _x;
        y = _y;
        z = _z;
        w = _w;
    }
}