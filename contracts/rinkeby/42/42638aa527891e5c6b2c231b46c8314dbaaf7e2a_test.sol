/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {

    function getNumber(uint x) public pure returns (uint) {

        x = x + 1;

        mulNumber(x);

        return x;
    }

    function mulNumber(uint x) public pure returns (uint) {
        return x**2;
    }
}