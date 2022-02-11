/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Texto {

    address owner;
    string text;

    constructor() {
        owner = msg.sender;
        text = "Hello World!";
    }

    function setText(string calldata _text) external {
        require(owner == msg.sender, "Only owner can modified the text!");
        text = _text;
    }

    function getText() public view returns (string memory){
        return text;
    }
}