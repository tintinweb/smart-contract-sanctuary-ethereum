/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract Seguimiento{
    string vendedor;
    string comprador;
    string item;
    uint precio;

    constructor(){
        
    }

    function setVendedor(string memory v) public {
        vendedor = v;
    }

    function setComprador(string memory c) public {
        comprador = c;
    }

    function setItem(string memory i) public {
        item = i;
    }

    function setItem(uint p) public {
        precio = p;
    }

}