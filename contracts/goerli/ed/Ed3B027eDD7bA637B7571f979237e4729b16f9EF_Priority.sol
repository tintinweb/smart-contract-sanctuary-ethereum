// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Priority {
    bool b;

    function flip() external {
        b = !b;
    }
}