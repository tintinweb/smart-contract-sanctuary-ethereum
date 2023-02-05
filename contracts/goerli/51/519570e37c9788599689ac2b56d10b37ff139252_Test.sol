/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract Test {

    uint nombre;

    function setNombre(uint _nombre) public {
        nombre = _nombre;
    }

    function getNombre() public view returns (uint) {
        return nombre;
    }

}