/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint public count;

    function increment() external  {
        count += 1;
    }

    function decrement() external {
        count -= 1;
    }
}