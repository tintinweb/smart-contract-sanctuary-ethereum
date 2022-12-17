/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT

// Contrato principal
contract ContratoBasico {
  // Variables
  string public nombre;
  uint public edad;

  // Constructor para inicializar el contrato
  constructor(string memory _nombre, uint _edad) public {
    nombre = _nombre;
    edad = _edad;
  }

  // Función para actualizar la edad
  function actualizarEdad(uint _edad) public {
    edad = _edad;
  }

  // Función para obtener la edad
  function obtenerEdad() public view returns (uint) {
    return edad;
  }
}