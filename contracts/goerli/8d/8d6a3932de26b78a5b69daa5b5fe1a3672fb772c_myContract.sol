/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract myContract {
    uint storedData = 10;
    string characterData = "";

    function setCharacterData(string memory szJSONData) public {
        characterData = szJSONData;
    }

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function getCharData() public view returns (string memory) {
        return characterData;
    }
}