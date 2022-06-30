//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TheFeed {
    string public word;

    function changeWord(string calldata newWord) external {
        word = newWord;
    }
}