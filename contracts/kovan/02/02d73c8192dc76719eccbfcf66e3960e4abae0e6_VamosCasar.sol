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


function DadosNoivo_Autoridade(address _conta, string memory _nome, string memory _genero) public {             // A Autoridade insere os dados do Noivo
    require(Autoridade== msg.sender, unicode"Apenas a Autoridade pode inserir os dados do noivo!");
    oNoivo.push(Noivo(_conta, _nome, _genero));        
}
function DadosNoiva_Autoridade(address _contaa, string memory _nomee, string memory _generoo) public {          // A Autoridade insere os dados da Noiva
    require(Autoridade== msg.sender, unicode"Apenas a Autoridade pode inserir os dados da noiva!");
    aNoiva.push(Noiva(_contaa, _nomee, _generoo));        
}

function consultarCasamentos(uint casamento) public view returns (address _conta, string memory _nome, string memory _genero, address _contaa, string memory _nomee, string memory _generoo){
    return (
    oNoivo[casamento].conta,                    // Funcionalidade:
    oNoivo[casamento].nome,                     // Após os dados serem inseridos pela autoridade
    oNoivo[casamento].genero,                   // Qualquer pessoa pode consultar a lista de casamentos que já existiram
    aNoiva[casamento].contaa,                   // Simplesmente inserindo o número do casamento: Casamento 0, Casamento 1, etc...
    aNoiva[casamento].nomee,                    // Receberá os dados pessoais de ambos os noivos: 
    aNoiva[casamento].generoo                   // Conta, nome e género.
    );
}

function CompromissoDoNoivo(address _conta, string memory _CompromissoNoivo) public {       // O Noivo insere aqui o seu compromisso para com a Noiva!
    Noivoo.push(CasamentoNoivo(_conta, _CompromissoNoivo));
    dizNoivo[_conta] = _CompromissoNoivo;

}

function CompromissoDaNoiva(address _conta, string memory _CompromissoNoiva) public {       // A Noiva insere aqui o seu compromisso para com o Noivo!
    Noivaa.push(CasamentoNoiva(_conta, _CompromissoNoiva));
    dizNoiva[_conta] = _CompromissoNoiva;
}


}