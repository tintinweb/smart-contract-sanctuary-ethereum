//SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    uint256 public favoriteNumber;
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        People memory newperson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });

        people.push(newperson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}