/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MyToken {

    uint256 public totalSupply;
    address public owner;

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public {
        if (msg.sender == owner) {
            owner = _newOwner;
        }
    }

    function changeOwnerWithError(address _newOwner) public {
        require(msg.sender == owner, "Only owner can change owner");
        owner = _newOwner;
    }
}