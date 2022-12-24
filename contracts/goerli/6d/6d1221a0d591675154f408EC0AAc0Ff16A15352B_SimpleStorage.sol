// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; //^0.8.8; // >=0.8.7 < 0.9.0

contract SimpleStorage {
    uint256 favoritNumber;

    mapping(string => uint256) public nameToFavoritNumber;

    struct People {
        uint256 favoritNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoritNumber) public virtual {
        favoritNumber = _favoritNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoritNumber;
    }

    function addPerson(string memory _name, uint256 _favoritNumber) public {
        //    People memory newPerson = People({favoritNumber:_favoritNumber, name:_name});
        //    people.push(newPerson)
        people.push(People(_favoritNumber, _name));
        nameToFavoritNumber[_name] = _favoritNumber;
    }
}