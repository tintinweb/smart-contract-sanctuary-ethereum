/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {
    mapping(address => string) public guestbook;

    function greet(string memory guestName) public {
      guestbook[msg.sender] = guestName;
   }
}