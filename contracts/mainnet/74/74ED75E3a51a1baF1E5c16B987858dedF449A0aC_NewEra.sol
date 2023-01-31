// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract NewEra {
    string public message = "Welcome to the new era.";
    function getMessage() public view returns(string memory){
        return message;
    }
}