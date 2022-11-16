/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Counter {
    uint public count;

    function increment() public {
        count += 1;
    }

    function get() external view returns (uint) {
        return count;
    }
}