/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract heteroStore {

    address public owner;
    string public arq;

    struct Registro {
        string valor;
        string timestamp;
    }

    mapping(string => Registro[]) registros;

    constructor(string memory _nombreContrato) {
        owner = msg.sender;
        arq = _nombreContrato;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function almacenarRegistro(string memory clave, string memory valor, string memory timestamp) public onlyOwner {
        registros[clave].push(Registro(valor, timestamp));
    }

    function obtenerValor(string memory clave, string memory timestamp) public view onlyOwner returns (string memory) {
        Registro[] memory registrosClave = registros[clave];
        for (uint i = 0; i < registrosClave.length; i++) {
            if (keccak256(bytes(registrosClave[i].timestamp)) == keccak256(bytes(timestamp))) {
                return registrosClave[i].valor;
            }
        }
        revert("No se encontro ningun registro para la clave y el timestamp proporcionados");
    }
}