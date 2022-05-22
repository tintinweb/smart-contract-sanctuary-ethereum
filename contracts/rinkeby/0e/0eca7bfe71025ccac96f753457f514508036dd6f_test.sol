/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {

    uint public x = 1;

    function getNumber() public returns (bool) {

        x = x + 1;

        mulNumber();

        return true;
    }

    function mulNumber() public returns (bool) {
        
        x = x * x;

        return true;
    }
}