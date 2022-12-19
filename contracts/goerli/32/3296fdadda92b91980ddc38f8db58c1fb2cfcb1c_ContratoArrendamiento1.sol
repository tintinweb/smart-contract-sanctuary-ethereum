/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT

// Este es un contrato inteligente de arrendamiento que permite al titular del bien inmueble el alquilar por un 
// período de tiempo determinado y una renta acordada.

//Actio1680

contract ContratoArrendamiento1 {

  address payable public arrendador;  // Dirección del titular del bien inmueble
  string public dniarrendador; // Documento de identidad del arrendador
  address public arrendatario; // Dirección del inquilino
  string public dniarrendatario; // Documento de identidad del arrendatario
  string public ubicacion; // Dirección del bien inmueble arrendado
  string public partidaregistral; // Número de partida registral
  uint public fechainicio; // Almacena la fecha de inicio del alquiler día-mes-año
  uint public fechafin;  // Almacena la duración del alquiler en meses
  uint public renta; // Precio de la renta en Wei, la renta es mensual
  string public allanamientofuturo; //El artículo 5 de la Ley 30201, que modifica el artículo 594° del Código 
  // Procesal Civil, establece que el arrendatario se compromete a desocupar el inmueble de manera anticipada 
  // y sin condiciones y a renunciar a cualquier acción legal que pueda intentar para obtener la devolución del 
  // inmueble una vez concluido el contrato de arrendamiento o en caso de incumplimiento del pago de la renta. 
  // Esto se aplica de acuerdo con lo dispuesto en el mencionado artículo

  // Constructor que inicializa el contrato y establece el propietario y el inquilino
    constructor( address payable _arrendador, string memory _dniarrendador, address _arrendatario, 
    string memory _dniarrendatario, uint _renta, string memory _ubicacion, string memory _partidaregistral,
    uint _fechainicio, uint _fechafin, string memory _allanamientofuturo) public {
    arrendador = _arrendador;
    dniarrendador = _dniarrendador;
    arrendatario = _arrendatario;
    dniarrendador = _dniarrendatario;
    ubicacion = _ubicacion;
    partidaregistral = _partidaregistral; // partida registral N° - Sede registral
    fechainicio = _fechainicio; // fecha de inicio 01-01-2023:  1674190800
    fechafin = _fechafin;
    renta = _renta;
    allanamientofuturo = _allanamientofuturo; // "si", el arrendatario se allana al allanamiento futuro
  }

 // Permite al titular del bien inmueble establecer la renta y la fecha fin del alquiler
  function terminosArrendamiento(uint _renta, uint _fechafin) public {
    require(arrendador == msg.sender, "Solo el arrendador puede establecer los terminos del alquiler.");
    renta = _renta;
    fechafin = _fechafin;
  }

  // Permite al titular del bien inmueble recibir la renta del alquiler
  function payRent() public payable {
    require(msg.value == renta, "El monto de la renta debe ser igual al precio del alquiler.");
    require(msg.sender == arrendatario, "Solo el arrendatario puede realizar la renta del alquiler.");
    arrendador.transfer(msg.value);
  }

  // Permite al titular del bien inmueble finalizar el alquiler antes del término acordado
  function endLease() public {
    require(arrendador == msg.sender, "Solo el propietario puede finalizar el alquiler.");
    arrendatario = address(0);
  }

  // Permite comparar la fecha de inicio del contrato con la fecha actual para verificar si el contrato ha expirado
  function hasExpired() public view returns (bool) {
  uint currentDate = now;
  return currentDate >= fechafin;
  }
}