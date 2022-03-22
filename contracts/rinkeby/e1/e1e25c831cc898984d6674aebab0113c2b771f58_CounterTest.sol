/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CounterTest {
    uint count = 0;

    function incCounter(uint incAmount) public returns (uint) {
        count += incAmount;
        return count;
    }

    function currentCount() public view returns (uint) {
        return count;
    }
}