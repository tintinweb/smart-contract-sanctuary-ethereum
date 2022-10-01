/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Colegio {
    address owner;
    
    mapping(address=>uint) counter;
    mapping(address=>mapping(uint=>uint)) notas;

    event NuevaNota(address indexed alumno, uint  nota);
    

    constructor() {
        owner = msg.sender;
    }

    modifier esAdmin {
        require(msg.sender==owner,string("No tiene permiso"));
        _;
    }

    function agregarNota(uint nota,address alumno) public esAdmin {
        require(nota>=1 && nota<=10,string("La nota debe ir de 1 a 10"));
        
        notas[alumno][counter[alumno]]=nota*(1e18);
        counter[alumno]++;
        emit NuevaNota(alumno,nota*(1e18));
    }
    function revisarPromedio(address alumno) public view returns(uint) {
        uint _tmpNotas;
        uint _tmpCounter;
        for (uint j=0; j<counter[alumno];j++) {
            _tmpNotas = notas[alumno][j]+_tmpNotas;
            _tmpCounter++;
        }
        uint promedio = _tmpNotas/_tmpCounter;
        
        return promedio;
    }
    function revisarNotas(address alumno) public view returns(uint[] memory) {
        uint[] memory _notas = new uint[](counter[alumno]);
        for (uint i=0; i<counter[alumno]; i++) {
            _notas[i]=notas[alumno][i];
        }
        return _notas;
    }
}