/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Hola{
    string public holaMundo = "Hola mundo desde solidity";

    function cambiarTexto(string memory _holaMundo)public {
        holaMundo = _holaMundo;
    }
}