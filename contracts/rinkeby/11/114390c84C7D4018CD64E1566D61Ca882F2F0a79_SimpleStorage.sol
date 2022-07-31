//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleStorage {

    uint256 public favoriteNumber;
    People public person = People({
    favoriteNumber : 2, name : 'Boris'
    });

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // favoriteNumber = favoriteNumber + 1;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory person = People({
        //     name: _name,
        //     favoriteNumber: _favoriteNumber
        // }); equivalent to --->

        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}