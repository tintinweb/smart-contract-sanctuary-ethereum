/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//uint
//string
//bool
//bytes32
//mapping
//vectores

contract Hello {
    //variables
    uint256 public numero = 5;
    uint256 public numero2 = 4;
    string public nombre;
    bool public datoBoolean;
    bytes32 internal datoByte = "HOLA";
    bytes32 internal datoByte2 = "HOLA";

    //tiempo
    uint256 public tiempo_actual = block.timestamp;
    uint256 public un_minuto = 1 minutes;
    uint256 public un_segundo = 1 seconds;
    uint256 public dia = 1 days;

    //casteo de variables
    uint256 public numero256 = 2560;
    uint8 public numero8 = uint8(numero256);
    uint256 public num256 = uint256(numero8);

    function suma() public view returns (uint256) {
        return (numero + numero2);
    }

    function comparacion() internal view returns (bool) {
        if (datoByte2 == datoByte) {
            return true;
        } else {
            return false;
        }
    }

    function mayor() public view returns (bool) {
        if (suma() > 18) {
            return true;
        } else {
            return false;
        }
    }

    function tuNombre(string memory _nombre) public returns (string memory) {
        nombre = _nombre;
        return (nombre);
    }

    //structs
    struct listaEstudiantes {
        string aula;
        uint256 cantidad;
    }

    listaEstudiantes public escuela = listaEstudiantes("A", 30);

    function nuevoAula(string memory _aula, uint256 _cantidad) public pure returns(listaEstudiantes memory){
        return listaEstudiantes(_aula, _cantidad);
    }

    function modificar(uint _cantidad) public returns(listaEstudiantes memory){
        escuela.cantidad = _cantidad;
        return escuela;

    }
     
     //mapping
     mapping (uint => uint) public promedioAlum;
     mapping(string=>mapping(string=>uint)) public escuelaYalumnos;

    function setMapping(uint _id, uint _promedio) public {
      promedioAlum[_id] = _promedio;
        
    }

    function setMappingEscuelaYalumnos(string memory _escuela,string memory _aulas, uint _cant) public returns(uint) {
        escuelaYalumnos[_escuela][_aulas] = _cant;
        return  escuelaYalumnos[_escuela][_aulas];
        
    }

    //array
    //string [5] public nombres = ["julio","josnny","maria","pedro","daniel"];
    string [5] public nombres;
    uint [] public edad;

    function setArray(string memory _nombre,uint _edad) public {
        nombres[0]= _nombre;
        edad.push(_edad);
        
    }
}