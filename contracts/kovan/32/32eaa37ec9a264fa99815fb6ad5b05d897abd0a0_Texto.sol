/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Texto {

    string texto;

    constructor() {
        texto = "Primera cadena.";
    }

    function setTexto(string memory _texto) public {
        texto = _texto;
    }

    function getTexto() public view returns (string memory){
        return texto;
    }
}