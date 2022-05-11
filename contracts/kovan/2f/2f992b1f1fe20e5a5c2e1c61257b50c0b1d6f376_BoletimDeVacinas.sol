/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BoletimDeVacinas {

    struct Utente {
        address conta;
        string nome;
    }

    Utente utentes;

    struct Vacina {
        uint data;
        uint validade;
        string farmaceutica;
    }

    Vacina[] vacinas;

    struct Entidade {
        address conta;
        string nome;
    }

    Entidade[] public entidades;
    mapping(address => Entidade) mapEntidade;

    struct Profissional {
        address conta;
        string nome;
    }

    Profissional[1] srs;
    mapping(address => Profissional) mapProfissional;

    constructor() {
        utentes.conta = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;
        utentes.nome = "Rodrigo Silva";

        srs[0].conta = 0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb;
        srs[0].nome = "Jose Medeiros";
    }

    function autorizar(address conta, string memory nome, bool adicionar) public {
        require (
            msg.sender == utentes.conta,
            unicode"Não tem permissão para interagir com esta função"
        );
        if (adicionar == true) {
            mapEntidade[conta].conta = conta;
            mapEntidade[conta].nome = nome;
            entidades.push(mapEntidade[conta]);
        }
        else {
            mapEntidade[conta].conta = address(0);
            mapEntidade[conta].nome = " ";
//            entidades.pop(Entidades[conta]);
        }
    }

    function vacinar(uint data, uint validade, string memory farmaceutica) public {
        require (
            msg.sender == mapProfissional[msg.sender].conta,
            unicode"Não tem permissão para interagir com esta função"
        );
        vacinas.push(Vacina({
            data: data,
            validade: validade,
            farmaceutica: farmaceutica
        }));
    }

    function consultar(uint dose) public view returns(uint data, uint validade, string memory farmaceutica) {
        require (
            msg.sender == mapEntidade[msg.sender].conta || msg.sender == mapProfissional[msg.sender].conta,
            unicode"Não tem permissão para interagir com esta função"
        );
        return (
            vacinas[dose].data, 
            vacinas[dose].validade,
            vacinas[dose].farmaceutica
        );
    }

    function doses() public view returns(uint TotalDoses) {
        require (
            msg.sender == mapEntidade[msg.sender].conta || msg.sender == mapProfissional[msg.sender].conta,
            unicode"Não tem permissão para interagir com esta função"
        );
        TotalDoses = vacinas.length;
        return TotalDoses;
    }
}