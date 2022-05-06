/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Heranca {

    mapping(string => uint) valorAReceber;
    //address é um tipo de variável
    address public owner = msg.sender;

    function escreveValor(string memory _nome, uint valor) public {
        require(msg.sender == owner); //somente continua com a escrita se o user for igual ao owner
        valorAReceber[_nome] = valor;
    }

    function pegaValor(string memory _nome) public view returns (uint) {

        return valorAReceber[_nome];
    }
}