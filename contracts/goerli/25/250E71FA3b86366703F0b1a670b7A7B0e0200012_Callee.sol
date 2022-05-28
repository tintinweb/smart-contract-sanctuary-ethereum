//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Callee {
    mapping(address => bool) switches;

    function setSwitch(address x) external {
        switches[x] = true;
    }
}