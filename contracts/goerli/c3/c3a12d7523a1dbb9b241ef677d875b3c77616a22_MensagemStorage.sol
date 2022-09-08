/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

contract MensagemStorage {
    uint256 totalMensagens;

    mapping(address => uint256) public ultimasMensagens;
    event NovaMensagem(address indexed from, uint256 timestamp, string message);

    struct Mensagem {
        address addr;
        string message;
        string nome;
        uint256 timestamp;
    }

    Mensagem[] private mensagens;

    constructor() {}

    function EnviarMensagem(string memory _message, string memory _nome)
        external
    {
        require(
            ultimasMensagens[msg.sender] + 1 minutes < block.timestamp,
            "Espere 1m"
        );

        /*
         * Atualiza o timestamp atual do sender
         */
        ultimasMensagens[msg.sender] = block.timestamp;
        totalMensagens += 1;
        mensagens.push(Mensagem(msg.sender, _message, _nome, block.timestamp));
        emit NovaMensagem(msg.sender, block.timestamp, _message);
    }

    function ObterMensagens() public view returns (Mensagem[] memory) {
        return mensagens;
    }

    function TotalMensagens() public view returns (uint256) {
        return totalMensagens;
    }
}