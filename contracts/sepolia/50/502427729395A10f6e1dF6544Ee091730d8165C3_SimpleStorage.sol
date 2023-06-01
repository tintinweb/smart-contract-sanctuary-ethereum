// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    People[] public people;

    mapping(string => uint256) public nameToFavNum;

    struct People {
        uint256 favNum;
        string name;
    }

    function store (uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retreive() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(uint256 _favNum, string memory _name) public {
        //People memory newPerson = People({favNum: _favNum, name: _name});
        people.push(People(_favNum, _name));
        nameToFavNum[_name] = _favNum;
    }
}