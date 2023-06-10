/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
* @title ContractName
* @dev ContractDescription
* @custom:dev-run-script scripts/deploy_with_ethers.ts
*/
contract Ejercicio1Sepolia {
    address public owner; // Dirección del propietario del contrato
    string public greeting; // Salu do almacenado

    event SaludoCambiado(address indexed _direccion, string _saludoAnterior, string _nuevoSaludo); // Evento para cuando se cambia el saludo
    event PropietarioCambiado(address indexed _propietarioAnterior, address indexed _nuevoPropietario); // Evento para cuando se cambia el propietario

    modifier soloPropietario() {
        require(msg.sender == owner, "Solo el propietario puede llamar a esta funcion"); // Verificar que el llamador sea el propietario
        _; // Continuar con la ejecución de la función
    }

    modifier direccionValida(address _direccion) {
        require(_direccion != address(0), "Direccion invalida"); // Verificar que la dirección no sea cero
        _; // Continuar con la ejecución de la función
    }

    constructor() {
        owner = msg.sender; // El propietario del contrato es la dirección del que lo despliega
        greeting = "Hola Ethereum"; // Saludo predeterminado
    }

    function cambiarSaludo(string memory _nuevoSaludo) public soloPropietario {
        emit SaludoCambiado(msg.sender, greeting, _nuevoSaludo); // Emitir evento SaludoCambiado al cambiar el saludo
        greeting = _nuevoSaludo; // Actualizar el saludo almacenado
    }

    function cambiarPropietario(address _nuevoPropietario) public soloPropietario direccionValida(_nuevoPropietario) {
        emit PropietarioCambiado(owner, _nuevoPropietario); // Emitir evento PropietarioCambiado al cambiar el propietario
        owner = _nuevoPropietario; // Actualizar el propietario del contrato
    }
}