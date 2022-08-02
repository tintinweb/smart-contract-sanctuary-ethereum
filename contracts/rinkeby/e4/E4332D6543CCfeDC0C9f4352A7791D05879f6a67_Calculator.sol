//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Calculator {

    uint public x;
    uint public y;

     constructor(uint _x, uint _y){
        x = _x;
        y = _y;
    }
    
    uint c;

     function restar(uint a, uint b) public {
        c = a - b;
    }

    function sumar(uint a, uint b) public returns (uint c) {
        c = a + b;
        return c;
    }

    function dividir(uint a, uint b) public {
        require(b > 0, "El divisor debe ser mayor que cero");
        c = a / b;
    }

    function multiplicar(uint a, uint b) public {
        c = a * b;
    }

    function obtenerResultado() public view returns (uint x) {
        return c;
    }
}