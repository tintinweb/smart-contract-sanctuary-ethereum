// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

contract BoxV3 {
    uint public val;
    uint public val2;

    function suma(uint _val) public {
        val = val + _val;
    }

    function resta(uint _val) public{
        val = val-_val;
    }
    function multiplicar(uint _val) public {
        val = val * _val;
        val2 = val;
    }

    function dividir(uint _val) public {
        val = val /_val;
        val2 = val;
    }

}