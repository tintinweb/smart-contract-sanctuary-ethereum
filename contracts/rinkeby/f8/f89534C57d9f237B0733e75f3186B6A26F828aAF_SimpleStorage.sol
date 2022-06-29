// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//EVM Compatible
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    uint256 public favoriteNumber;
    People public person = People(123, "Clinton");
    People public person1 = People(8, "Hazel");
    People public person2 = People(999, "Debra");

    People[] public people; //Dynamic array

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;


    function store(uint256 _favoriteNumber) public virtual{
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function retrieve()public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //Call Data -> exists during transaction, cannot be modified

    //Memory -> exists during transaction, can be modified

    //Storage -> exists on blockchain
}