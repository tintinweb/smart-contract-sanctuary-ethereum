// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract testing123 {
    function Try(string calldata test) external {
        testing = keccak256(abi.encode(test));
    }

    string public question;

    bytes32 public responseHash;

    bytes32 public testing;

    function Start(string calldata _question, string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }
}