// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favouriteNumber = 9;
    People public person = People({favouriteNumber: 3, name: "Luca"});

    mapping(string => uint256) public nameToFavouriteNumber;

    People[] public people;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        People memory newPeople = People(_favNumber, _name);
        people.push(newPeople);
        nameToFavouriteNumber[_name] = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}