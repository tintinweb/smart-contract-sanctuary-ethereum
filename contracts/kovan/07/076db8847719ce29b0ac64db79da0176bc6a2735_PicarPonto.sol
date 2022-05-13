/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract PicarPonto {

    struct Agente {
        address sender;
        string cargo;
        string nome;
        string data;
        string semana1;
        string semana2;
        string semana3;
        string semana4;
        string mes;
    }

    mapping(address => Agente) agente;

    Agente[] registos;

    constructor() {
        autorizarAgente(0x6f5216A08409A4357eC20D99743716f7eE62c7E7, "Empregador");
        autorizarAgente(0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb, "Empregado");
    }

    function autorizarAgente(address oAgente, string memory oCargo) private {
        agente[oAgente].sender = oAgente;
        agente[oAgente].cargo = oCargo;
        agente[oAgente].nome = "";
        agente[oAgente].data = "";
        agente[oAgente].semana1 = "";
        agente[oAgente].semana2 = "";
        agente[oAgente].semana3 = "";
        agente[oAgente].semana4 = "";
        agente[oAgente].mes = "";
        registos.push(agente[oAgente]);
    }

    function marcar(string memory Nome, string memory Data, string memory Semana1, string memory Semana2, string memory Semana3, string memory Semana4, string memory Mes) public {
        require(agente[msg.sender].sender == msg.sender, unicode"Não é Bem-vindo aqui.");
        require(bytes(Nome).length > 0, unicode"Tem de inserir o seu nome.");
        require(bytes(Data).length > 0, unicode"Tem de inserir a data de hoje.");
        require(fOuP(Semana1), unicode"2 Opções: P ou F para indicar presença ou falta.");
        require(fOuP(Semana2), unicode"2 Opções: P ou F para indicar presença ou falta.");
        require(fOuP(Semana3), unicode"2 Opções: P ou F para indicar presença ou falta.");
        require(fOuP(Semana4), unicode"2 Opções: P ou F para indicar presença ou falta.");
        require(fOuP(Mes), unicode"Tem de indicar qual é o mês");
        require(nova(Data), unicode"Esta data não pode ser usada");
        agente[msg.sender].nome = Nome;
        agente[msg.sender].data = Data;
        agente[msg.sender].semana1 = Semana1;
        agente[msg.sender].semana2 = Semana2;
        agente[msg.sender].semana3 = Semana3;
        agente[msg.sender].semana4 = Semana4;
        agente[msg.sender].mes = Mes;
        for (uint p = 0; p < registos.length; p++) {
            if (registos[p].sender == msg.sender){
                registos[p] = agente[msg.sender];
            }
        }
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
            registos[x].semana1, registos[x].semana2, registos[x].semana3, registos[x].semana4);
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