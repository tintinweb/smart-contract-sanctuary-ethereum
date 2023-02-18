/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TX_4 {

    event HelloWorld(address nextStep);

    function helloWorld(address ns) public {
        emit HelloWorld(ns);
    }
}