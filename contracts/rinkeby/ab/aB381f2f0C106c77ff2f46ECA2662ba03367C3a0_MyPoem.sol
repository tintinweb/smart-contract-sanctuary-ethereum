/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyPoem {
    string poem = "Jony Jony yes papa, eating sugar no papa... haha";
    string writer = "I am Sahil and I wrote this poem on 22nd of March 2022";

    function getDetails() public view returns (string memory, string memory) {
        return (poem, writer);
    }
}