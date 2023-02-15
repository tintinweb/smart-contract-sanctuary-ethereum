/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract StoreValue{
    uint value = 0;

    function set(uint v) public{
        value = v;
    }

    function get() public view returns(uint){
        return value;
    }
}