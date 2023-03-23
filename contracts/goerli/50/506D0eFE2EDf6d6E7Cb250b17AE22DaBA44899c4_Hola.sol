// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Hola {
    mapping(address => uint8) public balances;

    function sumar(uint8 _numero) public {
        balances[msg.sender] += _numero;
    }
    function restar(uint8 _numero) public {
        balances[msg.sender] -= _numero;
    }

    function getMyBalance()public view returns (uint8){
        return balances[msg.sender];
    }
}