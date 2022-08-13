// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //comment

contract SimpleStorage {
    //Types :  boolean , uint256 , int , address , bytes , string
    //bool hasFavoriteNumber = true;
    //uint256 favoriteNumber = 1;
    //string favoriteNumberInText = "1";
    //int256 favoriteInt=5;
    //address myAddress= 0x3763dfe3783........;
    //bytes32 favoriteBytes= "cat";

    //Default visibility is INTERNAL
    //Contract level vars are Global scope
    uint256 public favoriteNumber; // Default to 0

    //STRUCT -> creating custom type with struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //Create Single instance of struct
    //People public person = People({favoriteNumber: 2 , name: "Patrck"});

    //ARRAY -> Create Arrays with brackets -> []
    //uint256[] public favoriteNumbersList;
    People[] public people;

    //MAPPING (Dictionary)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata,memory,storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name)); //add to array
        nameToFavoriteNumber[_name] = _favoriteNumber; //add to mapping
    }
}