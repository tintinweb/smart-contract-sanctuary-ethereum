// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    //This will get initialized to 0.
    uint256 FavNumber;

    struct People {
        uint256 FavNumber;
        string name;
    }
    People[] public people; // array of people
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        FavNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return FavNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // memory (data will be stored only during the execution) o storage (data will persist even after the execution)
        people.push(People({FavNumber: _favoriteNumber, name: _name})); // or People(_favoriteNumber,_name)
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}