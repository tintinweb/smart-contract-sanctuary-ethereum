/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MiContrato{
    string texto;

    function Escribir(string memory _texto) public {
        texto = _texto;
    }

    function Leer() public view returns(string memory){
        return texto;
    }
}