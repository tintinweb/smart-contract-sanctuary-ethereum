/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.7.0 <0.9.0;

contract Contrato {

    string public mensagem;

    constructor(string memory mensagemInicial) {
        mensagem = mensagemInicial;
    }

    function alterarMensagem(string memory novaMensagem) public{
        mensagem = novaMensagem;
    }

}