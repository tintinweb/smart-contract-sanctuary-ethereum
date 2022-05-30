/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;



contract Votacion {
    // Presidente electo actualizado al ultimo voto.
    address public presidente;

    // Cuantos votos tiene cada candidato.
    mapping(address => uint256) numeroDeVotos;

    // Quien voto a quien.
    mapping(address => address) quienVotaste; 

    // Arma una nueva votacion donde el creador empieza siendo el presidente.
    constructor() {
        presidente = msg.sender;
        numeroDeVotos[presidente] = 1;
        quienVotaste[presidente] = presidente;
    }

    // Te permite votar a un candidato ingresando su address. Si ya votaste le saca el voto a tu candidato anterior. Actualiza el presidente de ser necesario.
    function votar(address candidato) external {
        require(candidato != address(0x0), "No se puede votar al candidato 0x0..0.");
        if (quienVotaste[msg.sender] != address(0x0)) {
            numeroDeVotos[quienVotaste[msg.sender]] -= 1;
        }
        numeroDeVotos[candidato] += 1;
        quienVotaste[msg.sender] = candidato;
        if (numeroDeVotos[candidato] > numeroDeVotos[presidente]) {
            presidente = candidato;
        }        
    }

    function miCandidato() external view returns (address) {
        address candidato = quienVotaste[msg.sender];
        require(candidato != address(0x0), "Todavia no votaste.");
        return candidato;
    }

    function obtenerNumeroDeVotos(address candidato) external view returns (uint256) {
        return numeroDeVotos[candidato];
    }

}