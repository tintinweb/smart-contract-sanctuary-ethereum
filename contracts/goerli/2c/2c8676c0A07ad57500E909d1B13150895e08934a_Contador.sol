// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Contador {
    uint256 public valor;

    function sumar() public {
        valor++;
    }

    function restar() public {
        valor--;
    }
}