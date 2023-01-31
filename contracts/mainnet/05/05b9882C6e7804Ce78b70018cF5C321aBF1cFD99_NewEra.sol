// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract NewEra {
    // No Comments
    string public message;
    constructor(string memory _message){
        message = _message;
    }
    function getMessage() public view returns(string memory){
        return message;
    }
}