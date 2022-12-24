/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// An example of a consumer contract that relies on a subscription for funding.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract test {
    uint256 public counter;
    function counterIncrement() public {
         counter++;
    }
}