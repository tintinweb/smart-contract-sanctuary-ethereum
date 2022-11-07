// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Tree {
    uint public apple;

    event Grow(uint apple);

    function grow() public {
        apple = apple + 1;
        emit Grow(apple);
    }
}