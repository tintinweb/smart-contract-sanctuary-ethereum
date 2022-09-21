/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Counter {
    uint public number = 0;


    function getCount() public view returns (uint) {
        return number;
    }

}