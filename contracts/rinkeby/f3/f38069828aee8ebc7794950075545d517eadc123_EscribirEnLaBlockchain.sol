/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
    string texto;

// calldata es una variable que proviene de una función

    function Escribir(string calldata _texto) public{
        texto = _texto;
    }

// View: Solo recupera información, no modifica.
    function Leer() public view returns(string memory){
        return texto;
    }

}