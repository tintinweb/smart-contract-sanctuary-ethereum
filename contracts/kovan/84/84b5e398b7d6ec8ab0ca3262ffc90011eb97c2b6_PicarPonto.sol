/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;
pragma experimental ABIEncoderV2;

contract PicarPonto {

    struct Agente {
        string cargo;
        string nome;
        string data;
        bool hora1;
        bool hora2;
        bool hora3;
        bool hora4;
    }

    mapping(address => Agente) private agente;

    constructor() {
        autorizarAgente(0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb, "Formando");
        autorizarAgente(0x829522f3Ca0421e9a16FE79f76BD5e12E4023a19, "Formador");
    }

    function autorizarAgente(address oAgente, string memory oCargo) private {
        agente[oAgente].cargo = oCargo;
        
    }

    function marcar(string memory Nome, string memory Data, bool Hora1, bool Hora2, bool Hora3, bool Hora4) public {
        agente[msg.sender].nome = Nome;
        agente[msg.sender].data = Data;
        agente[msg.sender].hora1 = Hora1;
        agente[msg.sender].hora2 = Hora2;
        agente[msg.sender].hora3 = Hora3;
        agente[msg.sender].hora4 = Hora4;
    }
}