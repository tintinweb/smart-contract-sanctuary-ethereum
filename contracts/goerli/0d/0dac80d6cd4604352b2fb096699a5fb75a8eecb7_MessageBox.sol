/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MessageBox {
    string mensaje;
    address public propietario;

    constructor() {
        mensaje  = "Hello World2!";
        propietario = msg.sender;
    }

    function setMessaje(string memory nuevoMensaje) public {
        mensaje = nuevoMensaje;
    }
    
    function destruirSC() public {
        require(msg.sender == propietario, "no eres el propietario, no tienes permisos");
         selfdestruct(payable(msg.sender));
    }

    function getMessage() public view returns(string memory) {
        return mensaje;
    }
    
}