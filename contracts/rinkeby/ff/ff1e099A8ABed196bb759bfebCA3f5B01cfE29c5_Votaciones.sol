/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/Votaciones.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Votaciones {
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    mapping (string => bytes32) id_candidato;

    mapping (string => uint) votos_candidatos;

    string [] candidatos;

    bytes32 [] votantes;

    function Postular(string memory _nombreCandidato, uint _edadCandidato, string memory _idCandidato) public {
        bytes32 hash_candidato = keccak256(abi.encodePacked(_nombreCandidato, _edadCandidato, _idCandidato));

        id_candidato[_nombreCandidato] = hash_candidato;

        candidatos.push(_nombreCandidato);
    }
    
}