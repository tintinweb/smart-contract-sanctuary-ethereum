/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    string public message = "Hello world!!!!!!";

    function AppendString(string memory msg) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
    function AppendString1(string memory msg,string memory msg1) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
    function AppendString2(string memory msg,string memory msg1,string memory msg2) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
    function AppendString3(uint256 a, string memory msg, string memory msg1, string memory msg2) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
    function AppendString4(string memory msg, uint256 a) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
}