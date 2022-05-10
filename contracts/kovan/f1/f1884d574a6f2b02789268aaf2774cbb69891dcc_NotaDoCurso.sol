/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract NotaDoCurso{

    struct Formando {
        address conta;
    }

    struct Formador {
        address conta;
        string curso;
        uint nota;
    }
    
    struct Conta {
        address sender;
        string cargo;
    }

    mapping(address => Conta) conta;
    mapping(address => uint) public saberNota;
    mapping(address => string) public saberCurso;

    Conta[] registos;

    Formando[] formandos;
    Formador[] formador;

    constructor() {
        autorizarConta(0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb, "Formador");
        autorizarConta(0x7799e5710B5210A45CF5e87F405D644d2A2A46C1, "Formando Luis Melo");
        autorizarConta(0x11cf464aB69fF79f6cb1023604FD86dC652D2C78, "Formando Rodrigo Serpa");
        autorizarConta(0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC, "Formando Rodrigo Silva");
    }


    function autorizarConta(address aConta, string memory oCargo) private {
        conta[aConta].sender = aConta;
        conta[aConta].cargo = oCargo;
        registos.push(conta[aConta]);
    }


    function darNota(address _conta, string memory _curso, uint _nota) public{


        formador.push(Formador(_conta, _curso, _nota));
        saberNota[_conta] = _nota;
        saberCurso[_conta] = _curso;

        for (uint p = 0; p < registos.length; p++) {
            if (registos[p].sender == msg.sender){
                registos[p] = conta[msg.sender];
            }
        }

     
    }

// Funcionalidade:
// Formador insere: endereço, curso e nota do formando;
// O Formando para saber a sua nota e curso insere: seu endereço.

}