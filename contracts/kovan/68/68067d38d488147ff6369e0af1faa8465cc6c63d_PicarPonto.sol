/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;
pragma abicoder v2;

contract PicarPonto {

    struct Agente {
        address sender;
        string cargo;
        string nome;
        string data;
        string hora1;
        string hora2;
        string hora3;
        string hora4;
    }

    mapping(address => Agente) agente;

    Agente[] registos;

    constructor() {
        autorizarAgente(0x6f5216A08409A4357eC20D99743716f7eE62c7E7, "Formandor");
        autorizarAgente(0x805a950522E1B5633AeCF9D2Fc86CAd5AF448AE8, "Formando");
    }

    function autorizarAgente(address oAgente, string memory oCargo) private {
        agente[oAgente].sender = oAgente;
        agente[oAgente].cargo = oCargo;
    }

    function marcar(string memory Nome, string memory Data, string memory Hora1, string memory Hora2, string memory Hora3, string memory Hora4) public {
        require(agente[msg.sender].sender == msg.sender, unicode"Não está autorizado a intragir com este contrato.");
        require(bytes(Nome).length > 0, unicode"É necessário inserir o seu nome.");
        require(bytes(Data).length > 0, unicode"É necessário inserir a data.");
        require(fOuP(Hora1), unicode"Deve usar exclusivamente P ou F para indicar presença ou falta.");
        require(fOuP(Hora2), unicode"Deve usar exclusivamente P ou F para indicar presença ou falta.");
        require(fOuP(Hora3), unicode"Deve usar exclusivamente P ou F para indicar presença ou falta.");
        require(fOuP(Hora4), unicode"Deve usar exclusivamente P ou F para indicar presença ou falta.");
        require(nova(Data), unicode"Já registou as presenças para esta data.");
        agente[msg.sender].nome = Nome;
        agente[msg.sender].data = Data;
        agente[msg.sender].hora1 = Hora1;
        agente[msg.sender].hora2 = Hora2;
        agente[msg.sender].hora3 = Hora3;
        agente[msg.sender].hora4 = Hora4;
        registos.push(agente[msg.sender]);
    }

    function relatorio() public view returns (Agente[] memory) {
        return registos;
    }

    function fOuP(string memory codigo) private pure returns (bool) {
        if (keccak256(abi.encodePacked("P")) == keccak256(abi.encodePacked(codigo)))
            return true;
        
        if (keccak256(abi.encodePacked("F")) == keccak256(abi.encodePacked(codigo)))
            return true;
        
        return false;
    }

    function nova(string memory data) private view returns (bool) {
        for (uint p = 0; p < registos.length; p++) {
            if (registos[p].sender == msg.sender){
                if (keccak256(abi.encodePacked(registos[p].data)) == keccak256(abi.encodePacked(data)))
                    return false;
                else
                    return true;
            }
        }
        return true;
    }
}