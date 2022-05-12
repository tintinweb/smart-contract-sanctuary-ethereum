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

address srs = 0x2700e973Eef4168b68F027d621B16Dea9B90dee9;
address autUtente = 0x6f5216A08409A4357eC20D99743716f7eE62c7E7;
address srs1 = 0x2700e973Eef4168b68F027d621B16Dea9B90dee9;
address autUtente1 = 0x6f5216A08409A4357eC20D99743716f7eE62c7E7;
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
    require(autUtente1 == msg.sender || srs1 == msg.sender , unicode"Não tem permissão para consultar as vacinas!");
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