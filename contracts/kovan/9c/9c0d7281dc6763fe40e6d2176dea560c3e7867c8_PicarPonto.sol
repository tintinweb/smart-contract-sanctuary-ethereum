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
        string hora1;
        string hora2;
        string hora3;
        string hora4;
    }

    mapping(address => Agente) agente;

    Agente[] registos;

    constructor() {
        autorizarAgente(0x1972f509A92D16d634DFE5Fc1bCCCAB92b6Ec71e, "Rodrigo");
        autorizarAgente(0x7e8f0f710d5b34f03B33062A7F87Ae7D3Fd106fa, "Frederico");
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
        registos.push(agente[oAgente]);
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