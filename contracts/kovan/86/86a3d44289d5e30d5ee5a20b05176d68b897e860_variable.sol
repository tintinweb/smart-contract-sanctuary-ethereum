/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract variable{
    uint x=5;
    uint public y;
    function set() public {
        y=x;
    }
}