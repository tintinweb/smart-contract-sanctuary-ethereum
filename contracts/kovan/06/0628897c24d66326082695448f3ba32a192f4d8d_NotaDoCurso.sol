/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract NotaDoCurso{

    struct Formando{

        address conta;
        string cargo;
        string curso;
        uint nota;
    }
    mapping(address => Formando) agente;

    Formando [] formandos;

      constructor() {
        autorizarAgente(0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb, "Jose Medeiros");
        autorizarAgente(0x11cf464aB69fF79f6cb1023604FD86dC652D2C78, "Rodrigo Serpa");
        autorizarAgente(0x7799e5710B5210A45CF5e87F405D644d2A2A46C1, "Luis Melo");
        autorizarAgente(0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC,"Rodrigo Silva");
    }

    function autorizarAgente(address oAgente, string memory oCargo) private {
        agente[oAgente].conta = oAgente;
        agente[oAgente].cargo = oCargo;
        agente[oAgente].curso = "";
        formandos.push(agente[oAgente]);
    }
    function darNota(address conta, string memory nomeCurso, uint nota) public {
        agente[msg.sender].conta = conta;
        agente[msg.sender].curso = nomeCurso;
        agente[msg.sender].nota = nota;

    }
   function lerNota() public view returns(address ) {

      // return conta;
   }

    function formando() public view returns (address, string memory, uint) {
        return getRegisto(1);
    }

       function getRegisto(uint x) private view returns (address, string memory, uint) {
        return (formandos[x].conta, formandos[x].curso, formandos[x].nota);
    }
}