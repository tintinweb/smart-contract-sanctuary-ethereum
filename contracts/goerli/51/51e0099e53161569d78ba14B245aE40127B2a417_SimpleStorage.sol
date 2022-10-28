//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage{

    uint256 public favoriteNumber;
    // People public person = People({favoriteNumber: 2, name: "Patrick"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //view pure
    function reteieve() public view returns(uint256){
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}