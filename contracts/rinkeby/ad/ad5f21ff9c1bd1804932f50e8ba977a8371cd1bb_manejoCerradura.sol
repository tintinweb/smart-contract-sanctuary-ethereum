/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract manejoCerradura{
    string estado;

    function enviarEstado (string memory _estado) public {
        estado=_estado;
    }
    function mostrarEstado() external view returns(string memory _estado){
        return estado;
    }
}