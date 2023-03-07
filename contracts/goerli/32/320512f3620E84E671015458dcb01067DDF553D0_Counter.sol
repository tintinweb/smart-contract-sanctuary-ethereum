/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.10;

contract Counter{

    uint public counter;

    function add(uint x) public returns(uint){
        counter = counter + x;
        return counter;
    }

   
}