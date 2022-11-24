/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Storage
{
    uint setData;
 
    function set(uint x) public{
        setData = x;
    }
     
    function get() public view returns (uint) {
        return setData;
    }
}