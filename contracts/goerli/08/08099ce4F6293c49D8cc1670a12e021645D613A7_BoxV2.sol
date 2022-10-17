// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

contract BoxV2 {
    uint public val;
    uint public val2;

    function multiplicar(uint _val) public {
        val = val * _val;
        val2 = val;
    }

    function dividir(uint _val) public {
        val = val /_val;
        val2 = val;
    }

}