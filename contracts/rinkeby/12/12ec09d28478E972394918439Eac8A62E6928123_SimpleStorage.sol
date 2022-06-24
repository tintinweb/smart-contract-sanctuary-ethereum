//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // uint256 favoriteNumber;
    // uint256 internal favoriteNumber = 0; // internal is default visibility
    uint256 public favoriteNumber = 0; // same, as 0 is default value

    People public person = People({favoriteNumber: 2, name: "Andrey"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // People[3] public people; //array with size of 3
    People[] public people; //array with dynamic size

    mapping(string => uint256) public nameToFavoriteNumber; // массив с ключами выбранного типа, похож на БД

    function store(uint256 _favoriteNumber) public virtual {
        // virtual - для возможности переписать функцию при наследовании контракта
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Типы хранения - calldata, memory, storage,
    // storage - дефолт, хранится постоянно
    // memory - хранится на момент вызова функции, удаляется после выполнения, для сложных типов включая строки тк строка это массив букв
    // calldata - то же что и memory, но его нельзя модифицировать
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}