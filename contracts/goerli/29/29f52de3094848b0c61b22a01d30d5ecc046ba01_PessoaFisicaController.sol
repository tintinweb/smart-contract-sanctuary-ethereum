// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract PessoaFisicaController {
    address public owner; //should be a multisig

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}