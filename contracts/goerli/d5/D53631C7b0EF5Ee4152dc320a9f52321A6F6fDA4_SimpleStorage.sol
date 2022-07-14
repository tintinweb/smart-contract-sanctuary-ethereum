/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12 - always start with that; ^means that any code above that version is okay

contract SimpleStorage {
    // without declaring any specific number, it get automatically initialized as 0
    uint256 favoriteNumber; // without visibility declaration, automatically "internal"

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    struct Car {
        string model;
        uint256 productionYear;
        string color;
    }

    Car[] public car;

    function addCar(
        string memory _model,
        uint256 _productionYear,
        string memory _color
    ) public {
        car.push(Car(_model, _productionYear, _color));
    }

    // calldata --> temp variables that cant be modified, memory --> temp variables that can be modified, storage --> permanent variables that
    // can be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure keywords allow to run a function without spending gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}

// every Contract has an address just like my wallet: 0xd9145CCE52D386f254917e481eB44e9943F39138
// EVM - Ethereum Virtual Mashine - Code Standard