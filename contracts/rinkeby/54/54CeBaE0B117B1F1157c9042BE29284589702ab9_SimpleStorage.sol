// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
// EVM compartable
// Avalanche, Fathom, Polygon
contract SimpleStorage{
    // by default the visibility is private
    uint256 favouriteNumber;
    // People public  person = People({
    //     favouriteNumber: 2, name: "Patrick"
    // });

    // this is a dictionary
    mapping(string=> uint256) public  nameToFavoriteNumber;


    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // this will create a people array
    // People[3] this will initial it to 3 people
    // People[] is a dynamic array
    People[] public people;

    // the virtual keyword will make this function overridable
    function store(uint256 _favoriteNumber) public  virtual {
        favouriteNumber = _favoriteNumber;
    }

    // view doesnt change the state of the contract 
    // You can't update the state
    // if you call a function inside a function that cost gas it will cost gas
    function retrieve() public view returns(uint256) {
        return  favouriteNumber;
    }

    // pure functions you can't read state 
    // but you can read the use it to do function calls
    // function add(uint x , uint y) public pure returns(uint256){
    //     return x + y;
    // }

    // calldata, memory, storage
    // memory means it will exist temporary can be modified
    // storage it is default and it is permenant and can be modified
    // calldata can't be modified
    // You have to to tell the data location of array, struct or mapping and a string is just an array of bytes
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // this is a way to add the name to the favaorite number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function allPersons() public view returns(People[] memory){
        return people;
    }
}