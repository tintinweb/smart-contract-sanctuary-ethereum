// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // 0.8.12 més usades


contract SimpleStorage {
    // booleana, uint, int, address, bytes, strings
    uint256 favoriteNumber;
    People[] public people;


    mapping (string=> uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual{
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint _favoriteNumber) public{
        People memory newPerson  = People({favoriteNumber: _favoriteNumber, name: _name});
        people.push(newPerson);
        nameToFavoriteNumber[_name]=_favoriteNumber;
    }
}