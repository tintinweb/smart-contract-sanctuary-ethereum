/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Example {
    string public message;

    function setMessage(string memory str) public {
        message = str;
    }

    function getMessage() public view returns (string memory){
        return message;
    }
}