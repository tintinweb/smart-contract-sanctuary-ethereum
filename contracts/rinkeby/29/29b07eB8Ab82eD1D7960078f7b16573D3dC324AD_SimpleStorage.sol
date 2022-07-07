//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0; // definition of the compiler version

contract SimpleStorage {
    //main contract definition

    uint256 favoriteNumber; //main variable for storing the number

    struct People {
        // definition of a new type (a bit like a new object)
        uint256 favoriteNumber;
        string Name;
    }

    People[] public people;

    mapping(string => uint256) public nametoToFavoriteNumber;

    // People public Person = People({favoriteNumber: 1, Name: "Mecenas"});

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function AddPerson(string memory _Name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, Name: _Name}));
        nametoToFavoriteNumber[_Name] = _favoriteNumber;
    }
}