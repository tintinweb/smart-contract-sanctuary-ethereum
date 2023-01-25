/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Saudacao {

    string private saudacao;

    function armazenarSaudacao(string memory _saudacao) public {
        saudacao = _saudacao;
    }

    function recuperarSaudacao() public view returns (string memory){
        return saudacao;
    }
}