/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Counter {
    int public count;

    constructor() {
        count = 0;
    }

    function increment() external {
        count += 1;
    }

    function decrement() external {
        count -= 1;
    }

    function getCount() public view returns(int) {
        return count;
    }
}