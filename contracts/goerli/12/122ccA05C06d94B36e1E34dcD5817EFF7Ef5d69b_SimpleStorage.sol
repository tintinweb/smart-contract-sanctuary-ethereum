// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// SimpleStorage es un contrato que almacena valores.
contract SimpleStorage {
    // this will get iniatialized to 0!
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    //Línea 18: mapping asocia una variable con otra
    mapping(string => uint256) public nameTofavoriteNumber;

    // Línea 21: la función almacena la variable favoriteNumber en el blockchain
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //memory solo se guarda la información durante la ejecución del contrato
    //storage se guarda la información durante y después de la ejecución del contrato
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameTofavoriteNumber[_name] = _favoriteNumber;
    }
}