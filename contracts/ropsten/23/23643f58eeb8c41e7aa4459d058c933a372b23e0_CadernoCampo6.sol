/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract CadernoCampo6 {

    struct PreparoSolo {
        string operacoes_realizadas;
        bool praticas_conservacionistas_adocao;
        string[] praticas_conservacionistas;
    }

    struct Lote {
        uint64 num;
        string cultura;
        string cultura_anterior;
        PreparoSolo preparo_solo;
    }

    struct Propriedade {
        string nome;
        uint64 area_cultivada;
        uint64 area_total;
        //uint64[] lotes;
    }

    struct Cliente {
        address adr;
        string nome;
        string email;
    }


    event NovoCliente(address adr , string nome, string email);
    
    event CadernoCampoCreation(
        address adr,
        uint256 data,
        string cep,
        Propriedade prop,
        Lote lote
    );

    modifier apenasDono {
        assert(msg.sender == dono);
        _;
        }

    modifier apenasCliente {
        assert(clientes[msg.sender].adr  !=  0x0000000000000000000000000000000000000000);
        _;
    }

    address dono;
    
    constructor() {
        dono = msg.sender;  
    }
    // DATA 
    mapping(address => Cliente) clientes;

    // METHODS

    function addCliente(address adr,
    string memory nome, string memory email) 
    external apenasDono() {
        Cliente storage to = clientes[adr];
        to.adr = adr;
        to.nome = nome;
        to.email = email;
        emit NovoCliente(adr,nome, email);
    }


    function addCadernoCampo(
        string memory cep,
        uint64 area_cultivada,
        uint64 area_total,
        string memory nome_propriedade,
        uint64 num_lote, 
        string memory cultura,
        string memory cultura_anterior,

        string memory operacoes_realizadas,
        string[] memory praticas_conservacionistas,
        bool praticas_conservacionistas_adocao

    ) external apenasCliente() {
        emit CadernoCampoCreation(
            msg.sender, block.timestamp, cep,
            
            Propriedade(nome_propriedade, area_total, area_cultivada),
            
            Lote(num_lote, cultura, cultura_anterior, 
            PreparoSolo(operacoes_realizadas, praticas_conservacionistas_adocao, praticas_conservacionistas))
        );
    }

    function getClienteByAddress(address adr) public apenasDono() view returns(Cliente memory) {
        return clientes[adr];
    }
}