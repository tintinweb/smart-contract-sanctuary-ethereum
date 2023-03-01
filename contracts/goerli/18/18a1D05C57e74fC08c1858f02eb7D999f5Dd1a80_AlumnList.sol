/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/practica/AlumnList.sol

//SPDX-License-Identifier: MIT
pragma solidity^0.8.0;


    //usuario ha de poder marcar que ha asistido a clase, cada clase tendrá un id (numero)
    //el sc tendrá que guardar el propietario del mismo
    //funcion privada
    //funcion de crear nueva clase, que solo pueda llamar el owner (modificador)
    //contador de clases, las diferentes clases a las que han asistido

contract AlumnList {

   // struct Class {
      //  uint256 classId;
     //   string className;
        //alumno, ha asistido?
     //   mapping(address => bool) alumnAssistedToClass;
    //}

    uint256 public classesCounter; //0
    address public contractOwner = msg.sender; //0x0000

    //id de la clase, alumno ha asistido
    mapping(uint256 => mapping(address => bool)) public hasAttended;

    //Class[] allClasses;


    modifier isOwnerOfContract() {
        require(msg.sender == contractOwner, "you are not the owner");
        _;
    }

    function assistClass() public {
        hasAttended[classesCounter][msg.sender] = true;
    }

    //memory, se gener ale objeto en memoria    
    //uint addres bool no hace falta ponerle palabra memory o stores
    function createClass() public {
        _createClass();
    }

    function _createClass() internal isOwnerOfContract() {
        classesCounter += 1;
    }

}