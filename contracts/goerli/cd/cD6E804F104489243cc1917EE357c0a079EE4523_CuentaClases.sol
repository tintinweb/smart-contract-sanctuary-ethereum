/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/CuentaClases.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


    //Los usuarios han de poder marcar que han asistido a una clase, cada clase tendrá un id ( numero ) 
    //El smart contract tendrá que guardar el propietario del mismo
    //función privada 
    //función de crear nueva clase que solo pueda llamar el owner ( modificador )
    //contador de clases
  //comentario aleatorio

contract CuentaClases {

    //ESTADO GLOBAL
    uint256 public contadorClases;
    address public owner;

    //Modificador para verificar que el msg.sender es el owner
    modifier isOwner ()
    {
        require (msg.sender == owner, "You are not the owner");
        _;
    }
    mapping(uint256 => mapping(address => bool)) public listaAsistencia;
    //Constructor del contrato
    constructor (){
        owner = msg.sender;
    }

    //Funcion para añadir una clase
    function crearClase () external isOwner{
        contadorClases++;
    }

    //Funcion para apuntarte a una clase
    function apuntarseClase () public {
        listaAsistencia[contadorClases][msg.sender]=true;
    }
}