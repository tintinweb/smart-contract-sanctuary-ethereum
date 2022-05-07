/**
 *Submitted for verification at Etherscan.io on 2022-05-07
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
        autorizarAgente(0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb, "Formandor");
        autorizarAgente(0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC, "Formando");
    }

    function autorizarAgente(address oAgente, string memory oCargo) private {
        agente[oAgente].sender = oAgente;
        agente[oAgente].cargo = oCargo;
        agente[oAgente].nome = "";
        agente[oAgente].data = "";
        agente[oAgente].hora1 = "";
        agente[oAgente].hora2 = "";
        agente[oAgente].hora3 = "";
        agente[oAgente].hora4 = "";
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

    function resultados() public view
            returns(Agente memory linha1, Agente memory linha2) {
        linha1 = registos[0];
        linha2 = registos[1];
    }

    function formador() public view returns (address, string memory, string memory, string memory, 
        string memory, string memory, string memory) {
        return getRegisto(0);
    }

    function formando() public view returns (address, string memory, string memory, string memory, 
        string memory, string memory, string memory) {
        return getRegisto(1);
    }

    function getRegisto(uint x) private view returns (address, string memory, string memory, string memory, 
        string memory, string memory, string memory) {
        return (registos[x].sender, registos[x].cargo, registos[x].nome,
         registos[x].hora1, registos[x].hora2, registos[x].hora3, registos[x].hora4);
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