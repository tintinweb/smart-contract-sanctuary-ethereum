/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.7;


contract HelloWorld {
    uint storeData;

    function get() public view returns (uint) {
        return storeData;
    }

    function set(uint x) public {
        storeData = x;
    }

    function add(uint x) public {
        storeData += x;
    }
}