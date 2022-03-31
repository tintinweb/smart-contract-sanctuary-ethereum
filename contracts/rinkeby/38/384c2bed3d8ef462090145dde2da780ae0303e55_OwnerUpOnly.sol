/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

contract OwnerUpOnly {
    address public immutable owner;
    uint256 public count;

    constructor() {
        owner = msg.sender;
    }

    function increment() external {
        require(msg.sender == owner, "only the owner can increment the count");
        count += 1;
    }
}