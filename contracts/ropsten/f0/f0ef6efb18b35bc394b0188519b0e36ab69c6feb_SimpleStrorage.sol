/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStrorage {
    uint storeData;

    function set(uint x) public {
        storeData = x;
    }

    function get() public view returns (uint) {
        return storeData;
    } 
}