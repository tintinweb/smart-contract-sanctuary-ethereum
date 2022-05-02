/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Conchiglia {

    mapping (address => uint) public conchiglie;

    constructor () {
        conchiglie[0x1be944a56FCe55d63e14b50f41B5FE0Ad3627FD1] = 100;
    }

    function transfer (address destinatario, uint quante) public {
        require (conchiglie[msg.sender] >= quante, "Non hai abbastanza conchiglie!");
        conchiglie[msg.sender] -= quante;
        conchiglie[destinatario] += quante;
    } 

}

// Chi     |   Cosa
// ----------------
// 0x123   |   10
// 0xABC   |   5
// 0x555   |   30