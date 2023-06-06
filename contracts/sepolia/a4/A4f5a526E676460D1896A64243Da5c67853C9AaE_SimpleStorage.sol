/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier:MIT

pragma solidity 0.8.7; // Ciao! Questo è un commento.

// pragma solidity ^0.8.0;
// pragma solidity >= 0.8.0 <0.9.0;

contract SimpleStorage {
    // boolean, uint, int, string, address, bytes
    /* string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0xf351175A52F559AaFEde02Bfe7A8DD48b6eB31FC;
    bytes32 favoriteBytes = "cat"; */
    //bool hasFavoriteNumber = true;

    //This (favoriteNumber) gets initialized to zero!
    uint public favoriteNumber; //since not specified, the variable favoriteNumber is defined as storage by default
    People public person = People({favoriteNumber: 2, name: "Patrick"});

    mapping(string => uint256) public nameToFavoriteNumber; //mapping (i.d. dictionary) where each string name is mapped to his associated uint256 favoriteNumber

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //people.push(People(_favoriteNumber, _name));      versione corta e senza memory keyword
        /*

        oppure

        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);

        oppure
        */

        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    /* function add() public pure returns (uint256){
        return (1 + 1);
    } */
}