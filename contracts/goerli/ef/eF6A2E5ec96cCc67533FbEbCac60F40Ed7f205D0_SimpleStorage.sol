// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // this gets initialized to zero!
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // The keyword struct creates a new type
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // this creates a list of type People and its public
    // and its stored as a variable with the name: people
    People[] public people;

    //uint256[] public favoriteNumbersList;
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    // view -> disallows any modification of the blockchain
    // only read
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}