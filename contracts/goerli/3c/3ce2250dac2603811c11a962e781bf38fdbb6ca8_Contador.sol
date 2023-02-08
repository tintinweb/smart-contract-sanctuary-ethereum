/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Contador {
    int public contador;

    function sumar()public returns(int){
        contador = contador + 1;
        return contador;
    }
    function restar()public returns(int){
        contador = contador - 1;
        return contador;
    }
}