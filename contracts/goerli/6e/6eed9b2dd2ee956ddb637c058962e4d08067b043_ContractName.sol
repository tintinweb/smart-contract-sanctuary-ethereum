/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract ContractName {
    string mensaje;

    constructor() {
        mensaje  = "Hello World!";
    }

    function setMessaje(string memory nuevoMensaje) public {
        mensaje = nuevoMensaje;
    }

    function getMessage() public view returns(string memory) {
        return mensaje;
    }
    
}