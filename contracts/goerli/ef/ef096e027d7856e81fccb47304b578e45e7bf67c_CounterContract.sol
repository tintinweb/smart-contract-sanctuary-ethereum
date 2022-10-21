/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract CounterContract{
    uint public counter;

    function increment() public{
        counter+=1;
    }
}