// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint favoriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping (string => uint256) public nametofavouriteNumber;

    People[] public people;

    function store(uint _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns(uint){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {

        People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        people.push(newPerson);
        nametofavouriteNumber[_name] = _favouriteNumber;
        // people.push(People(_favouriteNumber, _name));
    }
}