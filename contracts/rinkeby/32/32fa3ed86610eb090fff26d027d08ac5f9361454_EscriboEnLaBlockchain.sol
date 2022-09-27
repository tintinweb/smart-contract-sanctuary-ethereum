/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//Primera linea es la licencia (Publica o privada)
// SPDX-License-Identifier: MIT

//Segunda linea define al version en la que se compila 
pragma solidity >=0.7.0 <0.8.0;

//Tercera linea indica el nombre del contrato

contract EscriboEnLaBlockchain{                            //Se define contrato y el nombre.
    string texto;                                           //Declaracion de variable tipo string (texto) que vivira en la blockchain.
    
    function Escribir(string calldata _texto) public{       //Se crea la funcion para grabar en la blockchain el texto con llamada de la funcion publica.
        texto = _texto;                                     //Se carga la variable llamada por la funcion en la variable texto, el texto escrito.
    }

    function Leer() public view returns(string memory){     //se define la funcion para leer en memoria y traer de la Blockchain el texto escrito
        return texto;
    }
}