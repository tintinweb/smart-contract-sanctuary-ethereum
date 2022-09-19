/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MyToken {
    uint256 public totalSupply;
    address public owner;

    constructor(uint256 totalSupply_){
        totalSupply = totalSupply_;
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }

    function changeOwnerWithError(address newOwner) public {
        require(msg.sender == owner, "Not the owner");
        owner = newOwner;
    }


}