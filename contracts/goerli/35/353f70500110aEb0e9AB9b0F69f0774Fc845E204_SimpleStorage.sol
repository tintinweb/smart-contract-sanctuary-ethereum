// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    //used the virtual keyword so this contract is being inherited
    //in another account.

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //1- push array in first way
        //People memory newPerson  =  People ({favoriteNumber: _favoriteNumber, name:_name});
        //people.push(newPerson);

        // push array in second way
        people.push(People(_favoriteNumber, _name)); //array
        nameToFavoriteNumber[_name] = _favoriteNumber; //mapping
    }
}