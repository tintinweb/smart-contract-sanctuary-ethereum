// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Box4 {
    uint public votes;


    function add() public {
        votes++;
    }
    function sub() public {
        votes--;
    }
}