/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NotaDoCurso{
/*
Formador:
José Medeiros 	0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb
 
Formandos:
Luís Melo	0x7799e5710B5210A45CF5e87F405D644d2A2A46C1
Rodrigo Serpa	0x11cf464aB69fF79f6cb1023604FD86dC652D2C78
Rodrigo Silva	0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC
*/

    struct Formando {
        string nome;
        address conta;
        string curso;
        uint nota;
    } 
    
    struct Formador {
        string nome;
        address conta_formador;
    }

    string[3] nomes;
    address[3] contas;
    string st_curso = " ";
    uint st_nota = 0;
    
    Formando[3] formandos;
    Formador[1] formadores;

    mapping (address => Formando) map_formandos;

    constructor() {
        nomes[0] = "Luis Melo";
        nomes[1] = "Rodrigo Silva";
        nomes[2] = "Rodrigo Serpa";

        contas[0] = 0x7799e5710B5210A45CF5e87F405D644d2A2A46C1;
        contas[1] = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;
        contas[2] = 0x11cf464aB69fF79f6cb1023604FD86dC652D2C78;
        
        for (uint i = 0; i < nomes.length; i++) {
            formandos[i].nome = nomes[i];
            formandos[i].conta = contas[i];
            formandos[i].curso = st_curso;
            formandos[i].nota = st_nota;
        }

        formadores[0].nome = "Jose Medeiros";
        formadores[0].conta_formador = 0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb;
    }

    function darNota(address conta, string memory nomeCurso, uint nota) public returns(string memory warning) {
        require(msg.sender == formadores[0].conta_formador);
        require (nota !=0 && nota<=20);
        if (conta == formandos[0].conta) {
            nomeCurso = formandos[0].curso;
            nota = formandos[0].nota;
        }
        else if (conta == formandos[1].conta) {
            nomeCurso = formandos[1].curso;
            nota = formandos[1].nota;
        }
        else if (conta == formandos[2].conta) {
            nomeCurso = formandos[2].curso;
            nota = formandos[2].nota;
        }
        else {
            return string (abi.encodePacked("Student not found"));
        } 
    }

    function lerNota(address conta_aluno) view public returns(string memory nota_final) {
        if (conta_aluno == formandos[0].conta) {
            return string (abi.encodePacked(formandos[0].nota));
        }
        else if (conta_aluno == formandos[1].conta) {
            return string (abi.encodePacked(formandos[1].nota));
        }
        else if (conta_aluno == formandos[2].conta) {
            return string (abi.encodePacked(formandos[2].nota));
        }
        else {
            return string (abi.encodePacked("Student not found"));           
        }
    }
}