// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;


contract posgraduacao{

    uint256 public quantidadeAlunos;
    struct classe{
        bool presenca;
        string nome;
    }

    mapping(address => classe) public registroAluno;

    function presenca(string memory _meunome) external returns(uint256){
        ++quantidadeAlunos;
            registroAluno[msg.sender].nome = _meunome;
            registroAluno[msg.sender].presenca = true;
    return(quantidadeAlunos);
    }
    
}