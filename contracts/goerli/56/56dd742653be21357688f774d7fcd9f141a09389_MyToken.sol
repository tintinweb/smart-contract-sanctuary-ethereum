/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MyToken {
    // To je po defaultu 0 ce ne poves nic v konstruktorju.
    uint256 public totalSupply;

    // Address type
    address public owner;

    constructor(uint256 totalSupply_) {
        totalSupply = totalSupply_;
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }

    function changeOwnerWithAnError(address newOwner) public {
        require(msg.sender == owner, "Only owner can change owner");
        owner = newOwner;
    }
}