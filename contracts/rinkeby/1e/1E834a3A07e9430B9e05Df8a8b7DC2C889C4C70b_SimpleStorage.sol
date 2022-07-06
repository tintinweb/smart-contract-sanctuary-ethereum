// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteUint;
    struct People {
        string name; 
        uint256 age;
    }
    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteUint = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteUint;
    }

    function addPerson(string memory _name, uint256 _age) public {
        people.push(People(_name, _age));
        nameToFavoriteNumber[_name] = _age;
    }
}