/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Temp {
    mapping(address => string[]) internal words;

    function getWord(uint256 _index) public view returns (string memory) {
        string[] storage userWords = words[msg.sender];
        require(_index < userWords.length, "Index out of range");
        return userWords[_index];
    }

    function getWords() public view returns (string[] memory) {
        return words[msg.sender];
    }

    function getWordsCount() public view returns (uint256) {
        return words[msg.sender].length;
    }

    function addWord(string memory _text) public {
        words[msg.sender].push(_text);
    }
}