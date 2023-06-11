/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract PayAndHold {
    address payable public owner;

    // Al desplegar el contrato, el propietario es el que lo desplegó
    constructor() {
       owner = payable(msg.sender);
    }

    // Función para recibir pagos
    receive() external payable {}

    // Función para retirar los fondos del contrato
    function withdraw() public {
        require(msg.sender == owner, "Solo el propietario puede retirar fondos");
        owner.transfer(address(this).balance);
    }
}