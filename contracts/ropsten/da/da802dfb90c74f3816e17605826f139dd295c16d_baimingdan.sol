/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract baimingdan  {
    mapping (address => bool) public baimingdanlist;

    function jiadizhi (address dizhi) public {
        baimingdanlist[dizhi] = true;
    }
}