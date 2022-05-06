/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Mathall{
    function plus (uint a, uint b) public view returns (uint){
        return a+b;
    }
    function minus (uint a, uint b) public view returns (uint){
        return a-b;
    }
    function mal (uint a, uint b) public view returns (uint){
        return a*b;
    }
    function getelt (uint a, uint b) public view returns (uint){
        return a/b;
    }
}