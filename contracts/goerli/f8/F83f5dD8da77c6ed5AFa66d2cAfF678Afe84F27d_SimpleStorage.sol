// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract SimpleStorage {

    // DATATYPES
    // BOOLEAN , UINT , INT , ADDRESS , BYTES , STRINGA
    // VARIABLE
    // bool hasFavoriteNumber = true; // boolean variable 
    uint256 favoriteNumber; // uint256 variable
    // string  FavoriteText = 'Hello world'; // string variablr
    // bytes32 favoriteByte = "Dog";
    // address myaddress = 0x452A12ad65C41D9A88f2515Af6c6F364060D4CE8;

    // functions or methods execute a subset of code when called
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view function can just read a state from a contract
    function retrieve() public view returns(uint256)
    {
        return favoriteNumber;
    }
    
    //array && struct
    uint256[] myArray;
    // A mapping is a datastructure where a key is "mapped" to a single value
    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => string) public favoriteNumberToString;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People(
        {favoriteNumber:2, name:'Patrick'}
    );

    // uint256[] favoriteNumberList;
    People[] public people;
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPeople = People({favoriteNumber:_favoriteNumber, name:_name});
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        favoriteNumberToString[_favoriteNumber] = _name;
    }
    
}