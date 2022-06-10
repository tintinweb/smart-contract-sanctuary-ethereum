/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// File: contracts/Counter.sol

pragma solidity ^0.6.12;
 //SPDX-License-Identifier: UNLICENSED

contract Counter{
    uint public count;

    function increment() external {
        count += 1;
    }
}