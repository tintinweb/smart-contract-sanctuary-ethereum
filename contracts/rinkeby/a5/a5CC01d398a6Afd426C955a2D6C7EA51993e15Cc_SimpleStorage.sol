// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favouriteNumber;

    People[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber, 
            name: _name
        });
        people.push(newPerson);

        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}