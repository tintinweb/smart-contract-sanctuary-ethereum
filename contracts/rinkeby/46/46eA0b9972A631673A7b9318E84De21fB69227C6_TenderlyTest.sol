/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TenderlyTest {

    uint public count;

    function pass() external returns (uint) {
        count++;
        return 1;
    }
    
    function fail() external returns (uint) {
        count--;
        revert("Failed Transaction");
    }
}