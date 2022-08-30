/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Teste {
    int public numero;
    string public nome;
    function alteraNome(string memory _nome) public {
        nome = _nome;
    }
    function alteraNumero(int _numero) public {
        numero = _numero;
    } 


}