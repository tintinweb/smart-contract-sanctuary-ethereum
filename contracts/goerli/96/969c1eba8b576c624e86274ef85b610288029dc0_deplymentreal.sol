/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract deplymentreal{
    uint val;
    constructor()
    {
        val = 10;
    }
    function incr() public returns (uint)
    {
        val++;
        return val;
    }
    function decr() public returns (uint)
    {
        val--;
        return val;
    }
}