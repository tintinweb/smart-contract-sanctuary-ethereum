/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract VamosCasar {

struct Noivo {
    address conta;
    string nome;
    string genero;
}

Noivo[] oNoivo;

struct Noiva {
    address contaa;
    string nomee;
    string generoo;
}

Noiva[] aNoiva;

    mapping(address => string) public dizNoivo;
    mapping(address => string) public dizNoiva;

struct CasamentoNoivo {
    address conta;
    string CompromissoNoivo;
}

CasamentoNoivo[] Noivoo;

struct CasamentoNoiva {
    address conta;
    string CompromissoNoiva;
}

CasamentoNoiva[] Noivaa;

address Autoridade = 0x2700e973Eef4168b68F027d621B16Dea9B90dee9;


function DadosNoivo(address _conta, string memory _nome, string memory _genero) public {
    require(Autoridade== msg.sender, unicode"Apenas a Autoridade pode inserir os dados do noivo!");
    oNoivo.push(Noivo(_conta, _nome, _genero));        
}
function DadosNoiva(address _contaa, string memory _nomee, string memory _generoo) public {
    require(Autoridade== msg.sender, unicode"Apenas a Autoridade pode inserir os dados da noiva!");
    aNoiva.push(Noiva(_contaa, _nomee, _generoo));        
}

function consultar(uint casamento) public view returns (address _conta, string memory _nome, string memory _genero, address _contaa, string memory _nomee, string memory _generoo){
    return (
    oNoivo[casamento].conta,     
    oNoivo[casamento].nome,                     
    oNoivo[casamento].genero,   
    aNoiva[casamento].contaa,     
    aNoiva[casamento].nomee,                     
    aNoiva[casamento].generoo                           
    );
}

function CompromissoDoNoivo(address _conta, string memory _CompromissoNoivo) public {
    Noivoo.push(CasamentoNoivo(_conta, _CompromissoNoivo));
    dizNoivo[_conta] = _CompromissoNoivo;

}

function CompromissoDaNoiva(address _conta, string memory _CompromissoNoiva) public {
    Noivaa.push(CasamentoNoiva(_conta, _CompromissoNoiva));
    dizNoiva[_conta] = _CompromissoNoiva;
}


}