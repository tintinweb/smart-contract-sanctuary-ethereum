// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoritNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory person = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        people.push(person);
        nameToFavoritNumber[_name] = _favoriteNumber;
    }

    function getFavoriteNumberByName(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoritNumber[_name];
    }
}