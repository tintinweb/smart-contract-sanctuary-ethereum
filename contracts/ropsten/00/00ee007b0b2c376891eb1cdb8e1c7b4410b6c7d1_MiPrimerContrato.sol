/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.4.16 <0.9.0;

contract MiPrimerContrato{

    string saludo;

    function fijarSaludo( string memory _saludo ) public{

        saludo = _saludo;

    }

    function leerSaludo() public view returns( string memory) {
        return saludo;
    }
}