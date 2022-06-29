/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Votaciones{
    struct Votante{
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
        require(!votantes[votante].derechoAVotar, "Esta persona ya tiene permiso para votar");
        votantes[votante].derechoAVotar = true;
    }

    function votar(address votante, uint candidato) public {
        Votante storage sender = votantes[votante];
        require(sender.derechoAVotar, "No tiene derecho a votar");
        require(!sender.haVotado, "Ya ha votado");

        if(votante != funcionario){
            votantes[votante].haVotado = true;
        }
        
        candidatos[candidato].conteoVotos+=1;
    }

    function candidatoGanador() public view returns(uint propuestaGandora_){
        uint conteoVotosGanador = 0;
        for(uint p=1; p<candidatos.length; p++){
            if(candidatos[p].conteoVotos > conteoVotosGanador){
                conteoVotosGanador = candidatos[p].conteoVotos;
                propuestaGandora_ = p;
            }
        }
    }

    function nombreCandidatoGanador() public view returns(string memory nombreGanador_){
        nombreGanador_ = candidatos[candidatoGanador()].nombre;
    }

    function addCandidato(string memory candidato) public{
        require(msg.sender == funcionario, "Solo un funcionario puede dar permiso a agregar candidatos");
        candidatos.push(
            Candidato({
                nombre: candidato,
                conteoVotos: 0
            })
        );
    }
}