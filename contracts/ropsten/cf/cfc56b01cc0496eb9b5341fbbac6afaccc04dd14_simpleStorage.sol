/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.4.16 < 0.9.0;

contract simpleStorage {

    uint storedData;

    function set(uint x) private {
        storedData = x;
    }

    function get() private view returns (uint) {
        return storedData;
    }
}