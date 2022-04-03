/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FirstContract {
    string owner;

    constructor(string memory _name) {
        owner = _name;
    }

    function setName(string memory _name) public {
        owner = _name;
    }

    function getOwner() public view returns (string memory) {
        return owner;
    }
}