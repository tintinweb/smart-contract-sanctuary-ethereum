/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Contract es similar a una clase en otros lenguajes
contract SimpleStorage {
    //si no se le asigna valor por defecto queda en 0
    uint256 favoriteNumber;

    //mapping crea diccionarios o mappings, hay que poner una llave, y esta devuelve el valor que esta representa
    mapping(string => uint256) public nameToFavoriteNumber;

    //struct crea un nuevo tipo de dato, es un objeto
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //crea un array
    People[] public people;

    //Funcion que modifica el estado de la blockchain por lo que cuesta gas
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //funcion que no modifica el estado de la blockchain por lo que no cuesta gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}