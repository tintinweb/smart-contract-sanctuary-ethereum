/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract MiPrimerContrato {
    string saludo;

    function set(string memory _nuevoSaludos) public {
        saludo = _nuevoSaludos; // no se necesita 'this'
    }

    function get() public view returns (string memory) {
        return saludo;
    }
}