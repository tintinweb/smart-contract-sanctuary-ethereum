/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Name {
    address public owner;
    uint256 public amount;

    constructor() {
        owner = msg.sender;
        amount = 0;
    }
    function getOwner() public view returns (address) {
        return (owner);
    }
    function changeInt(uint256 num) public {
        amount = num;
    }
    function getAmount() public view returns (uint256) {
        return (amount);
    }
}