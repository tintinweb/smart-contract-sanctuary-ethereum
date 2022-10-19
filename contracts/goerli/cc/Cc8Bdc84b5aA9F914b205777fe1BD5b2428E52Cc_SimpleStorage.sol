/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // versão a ser utilizada

// Este programa roda em uma EVM - Ethereum Virtual Machine
// Exemplos: Avalanche, Fantom, Polygon

contract SimpleStorage {
    // this gets initialized later
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        // o atributo "virtual" permite que você faça override da função em outro arquivo
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}