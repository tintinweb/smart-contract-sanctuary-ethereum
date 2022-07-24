/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract chatBlockChain{
    string mensaje;

    function escribirMensaje(string calldata _mensaje) public{
        mensaje=_mensaje;
            }

    function leer() public view returns(string memory){
        return mensaje;
    }
        


}