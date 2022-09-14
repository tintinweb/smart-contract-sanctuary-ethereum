/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EscribirEnLaBlockchain{
    string texto;


    //call data es reservada para usar dentro de una funcion
    function Escribir(string calldata _texto) public{
        texto=_texto;
    }


    //usamos una funcion de view, cuando solo recupere datos
    //esta almacenado en memoria
    function leer() public view returns(string memory){
        return texto;
    }
}