/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract testers {
    string message = "hellos world";
    function showmsg() view public returns(string memory) {
        return message;
    }
    function cngmsg(string memory _msg) public returns(string memory) {
        message = _msg;
        return "changed!";
    }
}