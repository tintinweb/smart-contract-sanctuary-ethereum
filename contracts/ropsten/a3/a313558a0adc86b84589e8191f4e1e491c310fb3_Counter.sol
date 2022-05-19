/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Counter {

    // Private variable of type unsigned int to keep the number of counts
    uint256 private count = 0;

    // Function that increments our counter
    function increment() public {
        count += 1;
    }

    // Getter to get the count value
    function getCount() public view returns (uint256) {
        return count;
    }
}