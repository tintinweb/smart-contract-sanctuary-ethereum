/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract aula4 {
    string private name="estoque";
    string public symbol="RPC";
    uint8 public decimals=5;
    mapping (address=>uint) public balanceOf;
    uint public totalSupply; 
    function modifica (string memory _name) public {
       name=_name; 
        
    }
    function mostrarNome () public view returns (string memory) {
        return name;
     }
    constructor () {
        totalSupply=100_000 * 10**decimals;
        balanceOf [msg.sender] = totalSupply;
    }
    

}