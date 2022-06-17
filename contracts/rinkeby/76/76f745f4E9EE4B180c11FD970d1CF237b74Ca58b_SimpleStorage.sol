// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; //0.8.12 Latest version but not most stable

contract SimpleStorage {
    // Solidity fundamentals : boolean (defines true or false), unit ( Positive Number) ,int (Positive or negative), address,bytes
    uint256 FavriouteNumber; // This gets initialised to Zero.
    People public person = People({FavriouteNumber: 2, name: "Cooper"});

    mapping(string => uint256) public nametoFavNumbers;

    // List of people
    struct People {
        uint256 FavriouteNumber;
        string name;
    }

    // uint256[] public FavriouteNumberslist;
    People[] public people;

    function store(uint256 _FavriouteNumber) public virtual {
        FavriouteNumber = _FavriouteNumber;
        FavriouteNumber = FavriouteNumber + 1; // Changes state of the FavriouteNumber index.
        // retrieve(); which  Calls the recieve function below
    }

    // View and pure define wether gas is spent retrieving the function - no blockchain change
    // Only costs gas when a function calls those view and pure
    function retrieve() public view returns (uint256) {
        return FavriouteNumber;
    }

    // EVM storage places keywords; calldata (temporary unmodifiable variables) ,memory (temporary modifiable variables),
    // storage (permanent modifiable variable
    function Addperson(string memory _name, uint256 _FavriouteNumber) public {
        people.push(People(_FavriouteNumber, _name));
        nametoFavNumbers[_name] = _FavriouteNumber;
    }
}