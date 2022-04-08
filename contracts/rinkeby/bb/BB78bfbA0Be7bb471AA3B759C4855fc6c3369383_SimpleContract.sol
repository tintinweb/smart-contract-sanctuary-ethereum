//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleContract {
    function add() public pure returns (uint) {
        uint a = 1; 
        uint b = 2; 
        return (a+b);
    }
}