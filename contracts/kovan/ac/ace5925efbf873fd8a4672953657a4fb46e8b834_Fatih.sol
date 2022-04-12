/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// // SPDX-License-Identifier: Gazi
// File: contracts/FatihAkdik.sol


pragma solidity ^0.8.13;

contract Fatih {
    string public name;
    string public greetingPrefix = "Hello ";

    constructor(string memory  initialName) {
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greetingPrefix, name));

    }
}