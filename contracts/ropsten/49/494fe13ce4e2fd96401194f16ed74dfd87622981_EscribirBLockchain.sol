/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
 
contract EscribirBLockchain{

    string texto;

    constructor() {
        
    }
 
    function getTexto() external view returns(string memory) {
        return texto;
        
    } 
 
    function setTexto(string calldata _texto) external {
        texto = _texto;
    }
}