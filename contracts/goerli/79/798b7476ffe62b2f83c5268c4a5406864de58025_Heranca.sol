/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Heranca {

    mapping(string => uint) heranca;

    function addHerdeiro(string memory _nome, uint _valor) public {
        heranca[_nome] = _valor;
    }

    function recuperaHeranca(string memory _nome) public view returns (uint) {
        return heranca[_nome];
    }

}