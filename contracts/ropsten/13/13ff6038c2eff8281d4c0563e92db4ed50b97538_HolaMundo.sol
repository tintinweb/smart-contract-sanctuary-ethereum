/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract HolaMundo{
    string private _mensaje;
    
        constructor (string memory mensaje){
            _mensaje = mensaje;
        }
        function getMensaje() public view returns (string memory){
            return _mensaje;
        }     
    function setMensaje (string memory newMensaje) public{
        _mensaje = newMensaje;
    }
}