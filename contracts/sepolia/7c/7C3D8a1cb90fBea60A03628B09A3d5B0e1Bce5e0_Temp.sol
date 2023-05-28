/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Temp {
    mapping(address => string[]) private words;

    function getWord(uint _index) public view returns(string memory) {
        return words[msg.sender][_index];
    }

    function getWords() public view returns(string[] memory) {
        return words[msg.sender];
    }


    function getWordsCount() public view returns(uint) {
        return words[msg.sender].length;
    }


    function addword(string memory _text) public {
        words[msg.sender].push(_text);
    }
}