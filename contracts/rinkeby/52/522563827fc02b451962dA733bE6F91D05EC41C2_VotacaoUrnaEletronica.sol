// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

contract VotacaoUrnaEletronica {
    address public sindico;
    string public pauta;

    enum Opcao {
        Sim,
        Nao,
        Nulo,
        Abstencao
    }

    mapping(Opcao => address[]) voto;
    mapping(address => bool) moradores;

    constructor() {
        sindico = msg.sender;
        pauta = "Votacao sobre troca de interfone.";
    }

    function votar(Opcao _opcao) public {
        require(!moradores[msg.sender], "Morador ja votou!");
        voto[_opcao].push(msg.sender);
        moradores[msg.sender] = true;
    }

    function verResultado(Opcao _opcao) public view returns (address[] memory) {
        return (voto[_opcao]);
    }
}