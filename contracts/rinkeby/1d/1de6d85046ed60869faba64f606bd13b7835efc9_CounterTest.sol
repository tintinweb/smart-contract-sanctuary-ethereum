/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CounterTest {
    uint count = 0;

    function _incCounter(uint _incAmount) private returns (uint) {
        count += _incAmount;
        return count;
    }
}