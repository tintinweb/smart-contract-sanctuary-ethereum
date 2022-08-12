/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// declarar contrato
// declarar variables
// armar el constructor
// funcion para leer saldos
// funcion para enviar saldo a contrato
// funcion en contrato para enviar a billetera
// desplegar en testnet
// crear una tarea que se active a una hora determinada
// conectarse a un swap
// ejecutar un intercambio en un swap testnet
// conectarse a un flashloan
// ejecutar un prestamo

contract envios {
    
    //uint public valor;
    mapping (address => uint) public balance;

    function consultarSaldo(address _direccion) public view returns(uint){
        uint  saldo = _direccion.balance;
        return (saldo);
    }

    //obviamente está en memoria y por eso parece no funcionar
    uint public saldoRemitente = consultarSaldo(msg.sender);
    uint public saldoContrato = consultarSaldo(address(this));

    function depositarAContrato() external payable {
        balance[msg.sender] += msg.value;
    }

    function retirar() public {
        require(balance[msg.sender] > 0, "fondos insuficientes");
      
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "No se logro enviar el ether");

    }

}