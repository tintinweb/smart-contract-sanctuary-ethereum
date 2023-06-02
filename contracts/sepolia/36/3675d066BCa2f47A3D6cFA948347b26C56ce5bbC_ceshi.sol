/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
contract ceshi{
    uint shanglian;
    function first(uint bushu) public{
        shanglian=bushu;
    }
    function second() public view returns(uint){
        return shanglian;        
    }
}