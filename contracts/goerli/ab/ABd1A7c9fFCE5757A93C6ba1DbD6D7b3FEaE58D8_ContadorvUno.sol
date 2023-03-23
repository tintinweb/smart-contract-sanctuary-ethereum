/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract ContadorvUno {
    uint256 public valor;

    function sumar() public {
        valor++;
    }

    function restar() public {
        valor--;
    }
}