/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOracle {
    function valor() external returns (int);
}

contract OracleUser {
    IOracle public oraculo = IOracle(0x33A8b517099656932E494B059Cf3E5a5cF5f2871);

    function multiplicar(int valor) external returns (int) {
        return oraculo.valor() * valor;
    }
}