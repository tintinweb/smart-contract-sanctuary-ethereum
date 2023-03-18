// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract test {
    uint public x;
    function testing() public {
        require(msg.sender == address(0), "bruh");
        x++;
        }

}