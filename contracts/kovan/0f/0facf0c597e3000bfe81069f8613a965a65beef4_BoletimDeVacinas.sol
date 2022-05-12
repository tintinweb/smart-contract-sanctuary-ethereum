/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract BoletimDeVacinas{

struct Utente {
    address conta;
    string nome;
}

Utente[] utentes;

struct Vacina {
    uint numvacina;
    string data;
    string validade;
    string farmaceutica;
}


Vacina[] vacinas;

address srs = 0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb;
address autUtente = 0x7799e5710B5210A45CF5e87F405D644d2A2A46C1;
address[] public entidades;


function autorizar(address conta, bool adicionar) public {
    require(autUtente== msg.sender, unicode"Se não é o utente, dê meia volta!");


    if (adicionar==true){           //  Funcionalidade:
        entidades.push(conta);      //  Inserir a conta metamask que queremos adicionar à lista das entidades autorizadas
    }                               //  Escrever "true" para adicionar
    else entidades.pop();           //  Escrever "false" para remover o último registo.

}

function vacinar(uint _numvacina, string memory _data, string memory _validade, string memory _farmaceutica) public {
    require(srs== msg.sender, unicode"Boa tentativa :)");
    vacinas.push(Vacina(_numvacina, _data, _validade, _farmaceutica));        
}


function consultar(uint dose) public view returns (string memory _data, string memory _validade, string memory _farmaceutica){
    require(autUtente == msg.sender || srs== msg.sender , unicode"Não tem permissão para consultar as vacinas!");
    return (
    vacinas[dose].data,                     // São consultados a:
    vacinas[dose].validade,                 // Data, validade e farmacêutica
    vacinas[dose].farmaceutica              // através do número da dose do utente
    );
}


function doses()public view returns (uint totDoses){
    totDoses = vacinas.length;
    return (
        totDoses
    );
}

}