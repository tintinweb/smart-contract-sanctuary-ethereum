/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract VotoUNAM {
    
    struct Votante {
        address idUsuario;  // ID del usuario dentro de la red
        bool puedeVotar;    // Determina si una persona puede votar
        bool haVotado;      // Determina si el usuario ya voto
        uint valorVoto;     // Opción por la cual vota el usuario
    }

    struct Acusado {
        address idAcusado;  // ID del usuario acusado en la red
        uint votosFavor;    // Votos para que se quede el usuario
        uint votosContra;   // Votos para que se banee al usuario
    }

    // Variables
    address public propietario;                      // ID del usuario propietaria de esta encuesta
    mapping(address => Votante) private votantes;    // Lista de votantes
    Acusado public acusado;                          // Usuario acusado
    bool public encuestaFinalizada;                  // Indica si la encuesta está activa o no

    // Constructor del contrato
    // Solamente lo debe desplegar la persona que quiere crear una encuesta
    constructor(address _acusado) {
        // Verifica que el propietario y el acusado no sean la misma persona
        require(msg.sender != _acusado, "El creador de la encuesta no puede ser el acusado.");

        // Inicializa al propietario de la encuesta
        propietario = msg.sender;
        votantes[propietario].puedeVotar = true;

        // Inicializa atributos del acusado
        acusado.idAcusado = _acusado;
        acusado.votosFavor = 0;
        acusado.votosContra = 0;

        // Inicializa atributos de la encuesta
        encuestaFinalizada = false;
    }

    // Función del propietario para permitir a los usuarios votar
    function darPermisoVotar(address _votante) public {
        // Si las votaciones terminaron, se anula la transacción
        require(!encuestaFinalizada, "Esta encuesta ya fue finalizada.");

        // En caso de que no se sea el propietario, se anula la transacción
        require(msg.sender == propietario, "El propietario de la encuesta es el unico que puede dar permiso para votar.");

        // Recupera de la base los datos sobre el acusado sin editar los originales (palabra reservada memory)
        Acusado memory acusadoAct = acusado;
        require(_votante != acusadoAct.idAcusado, "No se le permite votar al acusado.");

        // Si el usuario ya votó, se anula la transacción
        require(!votantes[_votante].haVotado, "El usuario ya ejercio su voto.");

        // Se autoriza a un usuario para que pueda votar
        require(!votantes[_votante].puedeVotar, "El usuario ya fue autorizado para votar");
        votantes[_votante].puedeVotar = true;
    }

    // Función para que los usuarios autorizados voten
    function votar(uint _valor) public {
        // Si las votaciones terminaron, se anula la transacción
        require(!encuestaFinalizada, "Esta encuesta ya fue finalizada.");

        // Referencia al votante mediante un apuntador para modificar sus valores (palabra reservada storage)
        Votante storage usuarioAct = votantes[msg.sender];

        // Si el acusado intenta votar, se anula la transacción
        require(msg.sender != acusado.idAcusado, "El acusado no puede votar.");

        // Si el usuario no tiene permiso de votar, se anula la transacción
        require(usuarioAct.puedeVotar, "Este usuario no tiene derecho a votar.");

        // Si el usuario ya votó, se anula la transacción
        require(!usuarioAct.haVotado, "Este usuario ya ejercio su voto.");

        // Si el usuario ingresa un valor distinto, se anula la transacción
        require(_valor == 1 ||  _valor == 0, "Se debe ingresar el valor 0 o 1");

        usuarioAct.haVotado = true;
        usuarioAct.valorVoto = _valor;

        // Se suma el voto dependiendo la elección del votante
        if (_valor == 1){
            acusado.votosFavor += 1;
        } else {
            acusado.votosContra += 1;
        }
    }

    // Función que el propietario ejecuta para finalizar la encuesta
    function terminarVotacion() public {
        // Si otro tipo de usuario intenta finalizar la encuesta, se anula la transacción
        require(msg.sender == propietario, "El propietario de la encuesta es el unico que puede finalizarla.");

        // Si la votación se había finalizado anteriormente, se anula la transacción
        require(!encuestaFinalizada, "Esta encuesta ya habia sido finalizada.");

        encuestaFinalizada = true;
    }

    // Función de solo lectura para visualizar los resultados de la votación
    function resultadoVotacion() public view returns (uint _votosFavor, uint _votosContra) {
        require(encuestaFinalizada, "La encuesta no ha finalizado.");

        _votosFavor = acusado.votosFavor;
        _votosContra = acusado.votosContra;
    }
}