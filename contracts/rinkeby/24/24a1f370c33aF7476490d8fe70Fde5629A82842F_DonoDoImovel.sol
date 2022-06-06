/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DonoDoImovel {

    // variavel de estado
    string public dono;

    function alteraDono(string memory _novoDono) public {
        dono = _novoDono;
    }

}