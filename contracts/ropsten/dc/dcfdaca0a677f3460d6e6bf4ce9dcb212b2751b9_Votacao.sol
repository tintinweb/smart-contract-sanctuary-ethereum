/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Votacao {
    address public sindico;
    string public pauta;
    uint public numeroVotos;
    uint private termino;

    mapping(Opcao => address[]) votos;
    mapping(address => bool) condominos;

    // Sim=0, Nao=1, Nulo=2, Abstencao=3
    enum Opcao { Sim, Nao, Nulo, Abstencao }

    struct Resultado {
        Opcao opcao;
        uint numeroVotos;
        address[] votos;
    }

    event Votar(Opcao opcao, address condomino);

    constructor(string memory _pauta) {
        sindico = msg.sender;
        pauta = _pauta;
        termino = block.timestamp + 30 minutes;
    }

    function votar(Opcao _opcao) public {
        //require(block.timestamp <= termino, "Votacao terminou");
        require(msg.sender != sindico, "Sindico nao esta elegivel para votar");
        require(!condominos[msg.sender], "Condomino ja votou");

        votos[_opcao].push(msg.sender);
        condominos[msg.sender] = true;
        numeroVotos++;

        emit Votar(_opcao, msg.sender);
    }

    function verResultadoPorOpcao(Opcao _opcao) public view returns (address[] memory) {
        //require(block.timestamp > termino, "Votacao em andamento");

        return votos[_opcao];
    }

    function verResultadoGeral() public view returns (Resultado[] memory) {
        //require(block.timestamp > termino, "Votacao em andamento");

        Resultado[] memory resultados = new Resultado[](4);

        for (uint256 index = 0; index < 4; index++) {
            Opcao opcao = Opcao(index);
            address[] memory votantes = votos[opcao];

            resultados[index].opcao = opcao;
            resultados[index].numeroVotos = votantes.length;
            resultados[index].votos = votantes;
        }

        return resultados;
    }
}