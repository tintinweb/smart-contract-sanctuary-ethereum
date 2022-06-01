//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {

    uint favoriteNumber;
    People[] public people;

    struct People {
        uint favoriteNumber;
        string name;
    }

    mapping (string => uint) public nameToFavoriteNumber;

    function addPeople(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint _number) public virtual {
        favoriteNumber = _number;
    }

    function retrieve() public view returns(uint){
        return favoriteNumber;
    }

}