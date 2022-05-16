/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract SimpleStorage {
    uint storageData;

    function get() public view returns (uint) {
        return storageData;
    }

    function set(uint x) public {
        storageData = x;
    }
}