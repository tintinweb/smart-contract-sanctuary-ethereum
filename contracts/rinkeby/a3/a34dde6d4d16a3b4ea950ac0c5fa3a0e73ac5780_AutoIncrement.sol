/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

contract AutoIncrement {
    uint256 public counter = 0;

    function increment() public returns(bool) {
        counter += 1;
        return true;
    }
}