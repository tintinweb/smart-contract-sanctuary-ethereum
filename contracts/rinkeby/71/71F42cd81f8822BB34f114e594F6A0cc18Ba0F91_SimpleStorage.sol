/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // muy estable. el ^ indica que cualquier v de 0.8.7 y por encima se pueden utilizar

contract SimpleStorage {
    // bool hasFavoriteNumber = true;
    uint256 public favoriteNumber; // si no se inicializa, adquiere valor inicial de cero
    // People public person = People({favoriteNumber:2, name:"Patrick"});
    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x56Eddb7aa87536c09CCc2793473599fD21A8b17F;
    // bytes32 favoriteBytes = "cat" ;
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
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
        // o
        // people.push(People(_favoriteNumber, _name))
    }
}