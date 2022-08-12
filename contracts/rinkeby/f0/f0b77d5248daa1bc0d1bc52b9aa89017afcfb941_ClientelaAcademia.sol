/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;
 
contract ClientelaAcademia{
    struct Clientela {
        string NombreCliente;
        string Nivel; //básico, avanzado o profesional
    }
 
    Clientela[]  cliente;
    mapping (string => string) public BuscarCliente;
     mapping /*2*/ (string => string) public Buscarnivel;
 
    function Insertar (string memory NombreCliente, string memory Nivel) public {
        cliente.push(Clientela(NombreCliente, Nivel)) ;
        BuscarCliente[NombreCliente] = Nivel;
        Buscarnivel[Nivel] = NombreCliente;
    }
 
}