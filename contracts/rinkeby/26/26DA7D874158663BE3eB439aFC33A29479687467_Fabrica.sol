/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

pragma solidity ^0.8.7;

contract Modelo {

    uint public valor;

    constructor(uint _valor) {
        valor = _valor;
    }

}

contract Fabrica {

    Modelo[] public enderecos;

    function criaContrato(uint _valor) public {
        Modelo novo = new Modelo(_valor);
        enderecos.push(novo);
    }

}