/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract getpair {
    string[] texts;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function addText(string memory newText) public {
        texts.push(newText);
    }

    function getText(uint index) public view returns (string memory) {
        require(index < texts.length, "Index out of bounds");
        require (msg.sender == owner, "y");
        return texts[index];
    }
}