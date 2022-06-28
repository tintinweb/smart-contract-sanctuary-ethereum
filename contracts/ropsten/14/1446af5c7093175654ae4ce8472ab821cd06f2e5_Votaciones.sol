/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Votaciones{
    struct Votante{
        address votante;
        bool haVotado;
        bool derechoAVotar;
    }

    struct Candidato{
        string nombre;
        uint conteoVotos;
    }

    address public funcionario;

    mapping(address => Votante) public votantes;

    Candidato[] public candidatos;

    constructor(){
        funcionario = msg.sender;
        votantes[funcionario].derechoAVotar = true;
    }

    function permisoVotar(address votante) public {
        require(msg.sender == funcionario, "Solo un funcionario puede dar permiso a votar");
        require(!votantes[votante].haVotado, "Esta persona ya ha votado");
        require(!votantes[votante].derechoAVotar);
        votantes[votante].derechoAVotar = true;
    }

    function votar(uint candidato) public {
        Votante storage sender = votantes[msg.sender];
        require(sender.derechoAVotar, "No tiene derecho a votar");
        require(!sender.haVotado, "Ya ha votado");
        sender.haVotado = true;
        
        candidatos[candidato].conteoVotos+=1;
    }

    function candidatoGanador() public view returns(uint propuestaGandora_){
        uint conteoVotosGanador = 0;
        for(uint p=0; p<candidatos.length; p++){
            if(candidatos[p].conteoVotos > conteoVotosGanador){
                conteoVotosGanador = candidatos[p].conteoVotos;
                propuestaGandora_ = p;
            }
        }
    }

    function nombreCandidatoGanador() public view returns(string memory nombreGanador_){
        nombreGanador_ = candidatos[candidatoGanador()].nombre;
    }

    function addCandidato(string calldata candidato) public{
        candidatos.push(
            Candidato({
                nombre: candidato,
                conteoVotos: 0
            })
        );
    }
}