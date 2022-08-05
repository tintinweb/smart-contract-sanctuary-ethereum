/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Heranca {
    
    mapping(string => uint) valorHeranca;
    // MAPPING - É um dicionário.
    // MAPPING - A STRING sendo minha key, para um objeto UINT.

    function setValor(string memory _name, uint valor) public {
        // Esta função possui parâmetro. Obrigatório declarar os tipos e os nomes das variáveis.
        // PUBLIC - Função acessível para chamada de forma interna e externa.

        valorHeranca[_name] = valor;

        // MAPPING - Para setar a key declaro o nome do mapping seguido da variável entre cochetes.
        // MAPPING - Para setar o objeto declaro o nome da variável após a igualdade.

    }
    //visibilidade : public, private, external, internal.
    function getValor(string memory _name) public view returns(uint) {
        // Esta função possui parâmetro. Obrigatório declarar o tipo e o nome da variável.
        // PUBLIC - Esta função pode ser chamada internamente e externamente ao contrato.
        // VIEW - Esta função possui IDENTIFIER ( VIEW ). VIEW, pois não muda o estado das variáveis usadas.
        // VIEW - Pode ser chamada por um metodo CALL. Não gasta gás.

        return valorHeranca[_name]; 

        // MAPPING - "Return" em mapping. Declaro o nome do mapping e a key enter cochetes para que retorno o objeto correspondente.
        
    } 

}