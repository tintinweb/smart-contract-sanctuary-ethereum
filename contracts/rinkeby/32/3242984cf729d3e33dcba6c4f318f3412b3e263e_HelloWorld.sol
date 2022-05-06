/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld{
    string private _message;
    constructor() {
        _message = "Hello World";
    }
    function updateMessage(string memory newMessage) public{
        _message = newMessage;
    }
    function readMessage() public view returns (string memory){
        return _message;
    }
    function compareStrings(string memory a, string memory b) public pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}