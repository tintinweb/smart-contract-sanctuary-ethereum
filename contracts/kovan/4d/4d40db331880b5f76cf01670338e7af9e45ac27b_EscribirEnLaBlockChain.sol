/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT licencia 

pragma solidity >=0.7.0 <0.8.0; //Elegir version de copilador 

contract EscribirEnLaBlockChain{
    string texto; //Declarar variable

    function Escribir(string calldata _texto) public{
        texto = _texto;
    }

    function Leer() public view returns(string memory){
        return texto;
    }
}