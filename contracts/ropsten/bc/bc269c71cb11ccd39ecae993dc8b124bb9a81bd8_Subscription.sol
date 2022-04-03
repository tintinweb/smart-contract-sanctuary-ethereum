/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Subscription {
    string public name;

    constructor() {
        // This is a constructor
        name = "Subscription";
    }

    mapping(address => string) private names;

    function getNames() public view returns (string memory) {
        return names[msg.sender];
    }

    function setName(string memory _name) public {
        names[msg.sender] = _name;
    }
}