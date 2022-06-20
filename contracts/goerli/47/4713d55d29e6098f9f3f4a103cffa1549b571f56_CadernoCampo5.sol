/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract CadernoCampo5 {

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
        uint64[] lotes;
    }

    struct Cliente {
        address adr;
        string cep;
        string nome;
        string email;
        string[] propriedades;
    }


    event NovoCliente(address adr , string cep, string nome, string email);
    event EmailClienteUpdate(address adr , string email);
    event ClienteDelete(address adr);
    event NovaPropriedade(address adr, string nome,uint64 area_cultivada, uint64 area_total);
    event NovoLote(address adr,uint64 num, string cultura, string cultura_anterior);
    event LotePreparoSolo(address adr, string propriedade, uint64 num, PreparoSolo preparo_solo);

    modifier apenasDono {
        assert(msg.sender == dono);
        _;
        }

    modifier apenasCliente {
        assert(clientes[msg.sender].adr  !=  0x0000000000000000000000000000000000000000);
        _;
    }

    address dono = msg.sender;  


    // UTILS

    function getCountStringArray(string[] memory array) internal pure returns(uint count) {
    return array.length;
}

    function compareStrings(string memory a, string memory b) internal pure returns(bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}

    // DATA 
    mapping(address => Cliente) clientes;
    mapping(address => mapping(string => Propriedade)) propriedades;
    mapping(address => mapping(string => mapping(uint64 => Lote))) lotes;
    // *

    // MODIFIERS OVER DATA

    modifier existePropriedade(string memory nome_propriedade) {
        string[] memory to = clientes[msg.sender].propriedades;
        uint array_lenght = getCountStringArray(to);
        bool existence;
        for (uint i=0;i <= array_lenght; i++) {
            if (compareStrings(to[i], nome_propriedade) == true) {
                existence = true;
                break;
            }
            else {
                existence = false;
            }

        }

      assert(existence == true);
        _;
    }

    //*

    function addCliente(address adr, string memory cep,
    string memory nome, string memory email) 
    external apenasDono() {
        Cliente storage to = clientes[adr];
        to.adr = adr;
        to.cep = cep;
        to.nome = nome;
        to.email = email;
        emit NovoCliente(adr, cep, nome, email);
    }

    function addPropriedade(string memory nome,uint64 area_cultivada, uint64 area_total) 
    external apenasCliente() {
        Propriedade storage to = propriedades[msg.sender][nome];
        to.nome = nome;
        to.area_cultivada = area_cultivada;
        to.area_total = area_total;
        clientes[msg.sender].propriedades.push(nome);
        emit NovaPropriedade(msg.sender, nome, area_cultivada, area_total);
    }
    
    function addLote(uint64 num, string memory cultura, 
    string memory cultura_anterior, string memory nome_propriedade) 
    external apenasCliente existePropriedade(nome_propriedade) {
        Lote memory to;
        to.num = num;
        to.cultura = cultura;
        to.cultura_anterior = cultura_anterior;
        lotes[msg.sender][nome_propriedade][num] = to;
        propriedades[msg.sender][nome_propriedade].lotes.push(num);
        emit NovoLote(msg.sender, num, cultura, cultura_anterior);
    }

    function addLote_PreparoSolo(
        string memory operacoes_realizadas,
        bool praticas_conservacionistas_adocao,
        string[] memory praticas_conservacionistas,
        string memory nome_propriedade, uint64 num_lote )
        external apenasCliente existePropriedade(nome_propriedade){
            PreparoSolo memory to;
            to.operacoes_realizadas = operacoes_realizadas;
            to.praticas_conservacionistas_adocao = praticas_conservacionistas_adocao;
            to.praticas_conservacionistas = praticas_conservacionistas;
            lotes[msg.sender][nome_propriedade][num_lote].preparo_solo = to;
            

            emit LotePreparoSolo(msg.sender, nome_propriedade, num_lote, to);
    
        } 
       

    // VIEW FUNCTIONS

    function getClienteByAddress(address adr) public apenasDono() view returns(Cliente memory) {
        return clientes[adr];
    }

    function getPropriedades() 
    public apenasCliente() view returns(string[] memory) {
        return clientes[msg.sender].propriedades;
    }

    function getLoteByPropriedade(string memory nome_propriedade, uint64 numero_lote)
    public apenasCliente() view returns(Lote memory) {
        return lotes[msg.sender][nome_propriedade][numero_lote];
    }

    function getLote(string memory nome_propriedade, uint64 numero_lote) public view returns(Lote memory) {
        return lotes[msg.sender][nome_propriedade][numero_lote];
    }

}