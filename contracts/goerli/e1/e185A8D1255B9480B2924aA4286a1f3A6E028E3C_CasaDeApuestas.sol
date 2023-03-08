/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CasaDeApuestas {
    address owner;
    address ganadorApuesta;
    uint256 balancePropietario;

    struct Apuesta {
        uint256 id;
        uint256 balanceOpcionA;
        uint256 balanceOpcionB;
        uint256 balanceTotalApuesta;
        uint256 inicioApuesta;
        uint256 finalApuesta;
        bool ganaOpcionA;
        bool comisionReclamada; //Para evitar que se reclame mas de una vez la comisión.
        bool recompensaReclamada; //Para evitar que se reclame mas de una vez la recompensa.
    }


    mapping(uint256 => mapping(address => mapping(bool => uint256))) public apuestaAUsuarioAOpcionACantidad;
    Apuesta[] public apuestas;

    constructor () {
        owner=msg.sender;
    }

    modifier onlyOwner { //Nunca hacer un modifier de mas de una linea. Hacer una función privada y fuera.
      require(msg.sender == owner, "Not the owner");
      _;
    }
    modifier apuestaNoTerminada(uint256 _idApuesta) {
        require(block.timestamp < apuestas[_idApuesta].finalApuesta, "La apuesta ya ha terminado");
        _;
    }
    modifier apuestaTerminada(uint256 _idApuesta) {
        require(block.timestamp > apuestas[_idApuesta].finalApuesta, "La apuesta aun no ha terminado");
        _;
    }

    function crearApuesta(uint256 _horas, uint256 _minutos, uint256 _segundos) public onlyOwner {
        uint256 duracionApuesta = (_horas * 1 hours + _minutos * 1 minutes + _segundos * 1 seconds);
        uint256 id = apuestas.length;
        apuestas.push(Apuesta(id,0,0,0,block.timestamp, block.timestamp + duracionApuesta, false, false, false));
    }

    function _reclamarComision(uint256 _idApuesta) private onlyOwner apuestaTerminada(_idApuesta) {
        require(apuestas[_idApuesta].comisionReclamada == false, "Comision ya reclamada");
        uint256 comision = apuestas[_idApuesta].balanceTotalApuesta * 9 / 10; //Siempre multiplicar antes de dividir porque "0,x" se redondea a 0. Hay que quitar los ceros que sobren
        balancePropietario += comision;
        apuestas[_idApuesta].balanceTotalApuesta -= comision;
        apuestas[_idApuesta].comisionReclamada = true;
    }

    function decidirApuesta(uint256 _idApuesta, bool _ganaOpcionA) public onlyOwner apuestaTerminada(_idApuesta){
        apuestas[_idApuesta].ganaOpcionA = _ganaOpcionA;
        _reclamarComision(_idApuesta);
    }

    // Siempre usa msg.value en lugar de _amount para evitar pirateos. Investigar como.
    function apostar(uint256 _idApuesta, bool _ganaOpcionA) public payable apuestaNoTerminada(_idApuesta) {
        require(msg.value > 0, "Importe insuficiente");
        if(_ganaOpcionA == true) {
            apuestas[_idApuesta].balanceOpcionA += msg.value;
        } else {
            apuestas[_idApuesta].balanceOpcionB += msg.value;
        }
        apuestas[_idApuesta].balanceTotalApuesta += msg.value;
        apuestaAUsuarioAOpcionACantidad[_idApuesta][msg.sender][_ganaOpcionA] = msg.value;
    }


    function reclamarRecompensa (uint256 _idApuesta) public apuestaTerminada(_idApuesta){
        require(apuestas[_idApuesta].comisionReclamada, "Comision no reclamada por el propietario");
        require(apuestaAUsuarioAOpcionACantidad[_idApuesta][msg.sender][apuestas[_idApuesta].ganaOpcionA] != 0,"No has apostado");
        if(apuestas[_idApuesta].ganaOpcionA == true) {
            uint256 recompensa = (apuestaAUsuarioAOpcionACantidad[_idApuesta][msg.sender][true] * apuestas[_idApuesta].balanceTotalApuesta) / apuestas[_idApuesta].balanceOpcionA;
            // (bool success, ) = _to.call{value: _amount}("");
            (bool success, ) = msg.sender.call{value: recompensa}("");
            require(success,"Ether no enviado");
        } else {
            (apuestaAUsuarioAOpcionACantidad[_idApuesta][msg.sender][false] * apuestas[_idApuesta].balanceTotalApuesta) / apuestas[_idApuesta].balanceOpcionA;
        }
    }







}