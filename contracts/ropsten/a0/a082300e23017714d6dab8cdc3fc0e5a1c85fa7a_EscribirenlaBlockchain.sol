/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.1;

contract EscribirenlaBlockchain{
    string texto;

    function Escribir(string calldata _texto) public{
        texto = _texto;

    } 

    function leer() public view returns(string memory){
        return texto;
    }
 
}