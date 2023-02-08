/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract Contador {
    uint public contador;

    function sumar()public returns(uint){
        contador = contador + 1;
        return contador;
    }
    function restar()public returns(uint){
        contador = contador - 1;
        return contador;
    }
}