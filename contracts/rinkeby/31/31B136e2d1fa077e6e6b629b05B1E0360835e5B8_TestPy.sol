// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract TestPy {
    address public immutable owner = msg.sender;
    uint public x;

    function set(uint _x) external {
        require(msg.sender == owner, "not owner");
        require(_x > 0, "x = 0");
        x = _x;
    }
}