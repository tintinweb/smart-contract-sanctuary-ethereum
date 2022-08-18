/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Oraculo {
    int     public valor;

    constructor(int valor_) {
        valor         = valor_;
    }

    function actualizarValor(int nuevoValor) external {
        valor = nuevoValor;
    }
}