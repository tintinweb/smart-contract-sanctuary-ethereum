/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-Licence-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.8.14;

contract escribirBlockchain{
    string texto;

    function Escribir(string calldata _texto) public{
       texto = _texto;
    }

    function Leer() public view returns(string memory) {
        return texto;
    }


}