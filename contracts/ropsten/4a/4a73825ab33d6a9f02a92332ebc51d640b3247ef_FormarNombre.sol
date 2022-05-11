/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract FormarNombre{
    string nombreCompleto;

    function ArmarNombre(string calldata nombre, string calldata apellido) public{
        nombreCompleto = concatenate(nombre,apellido);
        
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,' ',b));
    }

    function Resultado() public view returns(string memory) {
        return nombreCompleto;
    }

}