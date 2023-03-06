/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

//Declaramos el contrato
contract Storage {

//Variable de estado
    uint256 number;

//funcion que recive un numero e inicializa variable de estado
    function store(uint256 num) public {
        number = num;
    }

// funcion para recuperar el numero insertado anteriormente. 
    function retrieve() public view returns (uint256){
        return number;
    }
}