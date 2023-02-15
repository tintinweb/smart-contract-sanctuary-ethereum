// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract SimpleStorage {
    uint256 public favoriteNumber = 5;

    // struct - build your own data type
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // array with People type
    People[] public people;

    // associate keys with values and store them in an unordered collection
    mapping(string => uint256) public nameToFavoriteNumber;

    // push to people array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        // use mapping key(name)/value(fav num) to store fav number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // add virtual to make it overrideable by inherited contracts
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions do not cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}