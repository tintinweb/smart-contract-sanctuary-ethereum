// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract NewsFeedReader {
    bool public subscribed = true;
    uint8 public age = 25;
    string public name = "Mark";

    function doubleAge() public view returns (uint8) {
        return age * 2;
    }

    function addExclamation() public view returns (string memory) {
        return string.concat(name, "!");
    }
}