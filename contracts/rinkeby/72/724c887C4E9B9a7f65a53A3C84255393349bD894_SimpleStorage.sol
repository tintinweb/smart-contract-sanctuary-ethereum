// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    //this will be initiallized to null or 0
    uint256 favoriteNumber;

    // you can take this as an object
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    // This maps the favoriteNumber property to a certain string value

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // you dont have to make a transaction on view and pure keywords
    function retrieve() public view returns (uint256) {
        //view functions dont make a state change
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        //this maps favoriteNumber property to name
    }
}