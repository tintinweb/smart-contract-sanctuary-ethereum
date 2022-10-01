/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract Ecuela {

    address directorDelInstituto;
    address alumno;
    mapping(address => uint[]) alumnoConNota;
    event seCargoUnaNota(address indexed alumno, uint nota);
    
    constructor(){
        directorDelInstituto=msg.sender;
    }
    
    modifier soloDirector(){
        require(msg.sender == directorDelInstituto, "Solo tiene permisos para cargar notas el director del colegio");
        _;
    }
    
    function cargarNota(address _alumno, uint _nota)public soloDirector returns(uint[] memory){
        uint[] storage notas = alumnoConNota[_alumno];
        notas.push(_nota);
        emit seCargoUnaNota(_alumno,  _nota);
        return notas;
    }

    function verMiPromedio()public view returns(uint){
        uint[] memory _misNotas = alumnoConNota[msg.sender];
        uint promedio = 0;
        for(uint i=0; i < _misNotas.length; i++){
            promedio += _misNotas[i];
        }
        return promedio/_misNotas.length;
    }
}