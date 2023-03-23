// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract ContadorEventos {
    event incrementoContador(uint);

    uint256 public valor;

    function sumar() public {
        valor++;
        emit incrementoContador(valor);
    }
}