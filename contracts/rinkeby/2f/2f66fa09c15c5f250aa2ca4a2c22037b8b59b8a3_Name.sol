/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Name {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    function getOwner() public view returns (address) {
        return (owner);
    }
}