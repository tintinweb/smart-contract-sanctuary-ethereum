/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract VotacionAD {

    struct VotanteEstructura {
        bool yaVoto;
        uint256 votoPor;
    }

    struct PropuestaEstructura {
        string nombrePropuesta;
        uint256 cantidadVotos;
    }

    address private fiscal;
    mapping(address => VotanteEstructura) private votantes;
    PropuestaEstructura[] public todasLasPropuestas;

    constructor() {
        fiscal = msg.sender;
    }

    function sumarPropuesta(string memory _nombrePropuesta) public {
        require(msg.sender == fiscal, "Solo el fiscal puede llamar a esta funcion");

        todasLasPropuestas.push(PropuestaEstructura({
            nombrePropuesta: _nombrePropuesta,
            cantidadVotos: 0
        }));
    }

    function votar(uint _indice) public {
        VotanteEstructura storage persona = votantes[msg.sender];
        require(!persona.yaVoto, "usted ya voto");

        persona.yaVoto = true;
        persona.votoPor = _indice;

        todasLasPropuestas[_indice].cantidadVotos += 1;
    }

    function obtenerIndiceGanador() private view returns(uint propuestaGanadora) {
        uint auxMayorCantidadVotos = 0;

        for(uint i = 0; i < todasLasPropuestas.length; i++) {
            if(todasLasPropuestas[i].cantidadVotos > auxMayorCantidadVotos) {
                auxMayorCantidadVotos = todasLasPropuestas[i].cantidadVotos;
                propuestaGanadora = i;
            }
        }
    }

    function ganadorNombre() public view returns(string memory ganador) {
        ganador = todasLasPropuestas[obtenerIndiceGanador()].nombrePropuesta;
    }
}