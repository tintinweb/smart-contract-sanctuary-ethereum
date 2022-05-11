/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract BoletimDeVacinas{

    struct Utente {
        address conta;
        string cargo;
        string Nome;
    }


    struct Vacina{

        string Data;
        string Validade;
        string farmaceutica;

    }

    Vacina[] vacinas;

    address[] srs = [0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb];
    address[]  entidades;
    Utente utentes;


    function autorizar(address conta, bool adicionar) public{
        if (adicionar == true){
            entidades.push(conta);
        }

    }
    function vacinar(string memory Data, string memory Validade, string memory farmaceutica) public{
        require(srs[0] == msg.sender, unicode"Não está autorizado a intragir com este contrato.");
        vacinas.push(Vacina({
            Data: Data,
            Validade: Validade,
            farmaceutica: farmaceutica
            

        }));

    }
        function consultar(uint dose) public view returns(string memory Data, string memory Validade, string memory farmaceutica) {

        return (
            vacinas[dose].Data, 
            vacinas[dose].Validade,
            vacinas[dose].farmaceutica
        );
    }
    function doses() public view returns(uint TDoses) {

        TDoses = vacinas.length;
        return TDoses;
    }
}