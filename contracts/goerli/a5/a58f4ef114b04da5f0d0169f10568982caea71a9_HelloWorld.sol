/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

contract HelloWorld {
    string private helloMessage = "Hello world3";

    function getHelloMessage() public view returns (string memory) {
        return helloMessage;
    }
}