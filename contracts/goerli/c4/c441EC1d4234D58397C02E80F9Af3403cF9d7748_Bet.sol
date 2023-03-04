/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// File: contracts/Bet.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bet {
    struct Apuesta {
        uint256 id;
        uint256 bote1; // Total apostado al equipo "local"
        uint256 bote2; // Total apostado al equipo "visitante"
        uint256 fechaLimite;
        uint8 ganador; // 0 = sin definir; 1 = "local", 2 = "visitante"
        bool comisionReclamada;
    }
    mapping (uint256 => mapping (address => mapping(uint8 => uint256))) intentos; // id_apuesta => participante => opcion => cantidad
    Apuesta[] apuestas;
    uint256 comision;
    address owner;

    constructor() {
        owner = payable(msg.sender);
        comision = 10;
    }

    modifier isOwner() { // Cada vez que se llama en una función, se ejecuta todo el codigo hasta el _;
        require(msg.sender == owner, "No eres el propietario");
        _;
    }

    function verCantidadDeApuestas() external view returns (uint256) {
        return apuestas.length;
    }

    function verApuesta(uint256 _id) external view returns (Apuesta memory) {
        require(_id < apuestas.length, "No existe apuesta con ese ID");
        return apuestas[_id];
    }

    function crearApuesta(uint256 _dias, uint256 _horas, uint256 _minutos) external isOwner {
        apuestas.push(
            Apuesta(
                /*id:*/ apuestas.length,
                /*bote1:*/ 0,
                /*bote2:*/ 0,
                /*fechaLimite:*/ dateToTimestamp(_dias, _horas, _minutos),
                /*ganador:*/ 0,
                /*comisionReclamada:*/ false
            )
        );
    }

    function dateToTimestamp(uint256 dias, uint256 horas, uint256 minutos) internal view returns (uint256) {
        return block.timestamp + (dias*24*60*60)+ (horas*60*60) + (minutos*60);
    }

    function decidirGanador(uint256 _id, uint8 _ganador) external isOwner {
        // Comprobar que no sea demasiado pronto
        require(apuestas[_id].ganador == 0, "El ganador ya se ha decidido");
        require(block.timestamp > apuestas[_id].fechaLimite, "No se puede terminar una apuesta antes de la fecha limite de apuesta");
        apuestas[_id].ganador = _ganador;
    }

    function entrarEnApuesta(uint256 _id, uint8 _opcion) external payable {
        // Comprobar que no sea demasiado tarde
        require(msg.value > 0, "Se debe apostar al menos 1 wei");
        require(block.timestamp < apuestas[_id].fechaLimite, "Ya no se puede participar en esta apuesta");
        require(_opcion == 1 || _opcion == 2, "Opcion no valida");

        // Registrar la apuesta
        (_opcion == 1) ? apuestas[_id].bote1 += msg.value : apuestas[_id].bote2 += msg.value; // Añadir al bote de la apuesta en sí
        intentos[_id][msg.sender][_opcion] += msg.value; // Añadir apuesta al registro de intentos
    }

    function reclamarPremio(uint256 _id) external { 
        // Comprobar que la apuesta esté definida
        require(apuestas[_id].ganador > 0, "Aun no se ha definido el resultado");

        // Calcular cuanta dinero le toca recibir
        uint256 total = apuestas[_id].bote1 + apuestas[_id].bote2;
        uint256 totalCorrectoApuesta = (apuestas[_id].ganador == 1) ? apuestas[_id].bote1 : apuestas[_id].bote2;
        uint256 participacionCorrectaSender = intentos[_id][msg.sender][apuestas[_id].ganador];
        uint256 premio = participacionCorrectaSender * total / totalCorrectoApuesta; // Formula de Alexfu
        uint256 premioDespuesDeComisiones = premio * 90 / 100;
        require(premioDespuesDeComisiones > 0, "No tienes premio que reclamar");

        // Descontar premios reclamados del registro
        require(intentos[_id][msg.sender][apuestas[_id].ganador] > 0, "");
        intentos[_id][msg.sender][apuestas[_id].ganador] -= totalCorrectoApuesta;

        // Enviar dinero
        (bool success,) = msg.sender.call{value: premioDespuesDeComisiones}("");
        require(success, "Failed to send Ether");
    }

    function reclamarComision(uint256 _id) external isOwner {
        require(apuestas[_id].comisionReclamada == false, "La comision ya ha sido reclamada");
        apuestas[_id].comisionReclamada = true; // Registrar comision reclamada

        // Comprobar que la apuesta esté definida
        require(apuestas[_id].ganador > 0, "Aun no se ha definido el resultado");

        // Calcular la comision
        uint256 cantidad = (apuestas[_id].bote1 + apuestas[_id].bote2) * comision / 100;

        // Enviar dinero
        (bool success,) = owner.call{value: cantidad}("");
        require(success, "Failed to send Ether");
    }

    // Si se llama al smart contract sin ninguna funcion...
    receive() external payable { }
}