// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract SimpleStorage {
    uint public favouriteNumber;

    function store(uint _number) public virtual {
        favouriteNumber = _number;
    }

    struct players {
        string lastname;
        uint number;
    }

    players public jugador = players({lastname: "Jordan", number: 23});

    players[] public jugadores;

    mapping(string => uint) public NombreToNumero;

    function cargarjug(string memory _apellido, uint _numero) public {
        jugadores.push(players(_apellido, _numero));
        NombreToNumero[_apellido] = _numero;
    }

    function retrieve() public view returns (uint) {
        return favouriteNumber;
    }
}