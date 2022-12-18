/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT

// Este es un contrato inteligente de arrendamiento que permite al titular el alquilar
// su propiedad a un inquilino por un período de tiempo determinado y un precio acordado.

contract ContratoArrendamiento {

  address payable public arrendador;  // Dirección del titular del bien inmueble
  address public arrendatario; // Dirección del inquilino
  uint public rentcost; // Precio del alquiler en soles
  string public houseloc; // Dirección del bien inmueble arrendado
  string public startDate; // Almacena la fecha de inicio del alquiler día-mes-año
  uint public duration;  // Almacena la duración del alquiler en meses

  // Constructor que inicializa el contrato y establece el propietario y el inquilino
    constructor( address payable _arrendador, address _arrendatario, uint _rentcost, 
    string memory _houseloc, string memory _startDate, uint _duration) public {
    arrendador = _arrendador;
    arrendatario = _arrendatario;
    rentcost = _rentcost;
    houseloc = _houseloc;
    startDate = _startDate;
    duration = _duration;
  }

 // Permite al propietario establecer el precio del alquiler y la duración del alquiler
  function setLeaseTerms(uint _rentcost, uint _duration) public {
    require(arrendatario == msg.sender, "Solo el inquilino puede establecer los terminos del alquiler.");
    rentcost = _rentcost;
    duration = _duration;
  }

  // Permite al propietario recibir el pago del alquiler
  function payRent() public payable {
    require(msg.value == rentcost, "El monto del pago debe ser igual al precio del alquiler.");
    require(msg.sender == arrendatario, "Solo el inquilino puede realizar el pago del alquiler.");
    arrendador.transfer(msg.value);
  }

  // Permite al propietario finalizar el alquiler antes del término acordado
  function endLease() public {
    require(arrendador == msg.sender, "Solo el propietario puede finalizar el alquiler.");
    arrendatario = address(0);
  }
}