/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract counter {

    uint public count = 0;

    function increment() public returns(uint) {
        count += 100;
        return count;
    }
}