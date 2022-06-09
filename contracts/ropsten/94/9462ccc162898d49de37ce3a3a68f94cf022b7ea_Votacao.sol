/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Votacao {
    address public sindico;
    string public pauta;
    uint public numeroVotos;

    mapping(Opcao => address[]) votos;
    mapping(address => bool) condominos;

    // Sim=0, Nao=1, Nulo=2, Abstencao=3
    enum Opcao { Sim, Nao, Nulo, Abstencao }

    event Votar(Opcao opcao, address condomino);

    constructor(string memory _pauta) {
        sindico = msg.sender;
        pauta = _pauta;
    }

    function votar(Opcao _opcao) public {
        require(msg.sender != sindico, "Sindico nao esta elegivel para votar");
        require(!condominos[msg.sender], "Condomino ja votou");

        votos[_opcao].push(msg.sender);
        condominos[msg.sender] = true;
        numeroVotos++;

        emit Votar(_opcao, msg.sender);
    }

    function verResultado(Opcao _opcao) public view returns (address[] memory) {
        return votos[_opcao];
    }
}