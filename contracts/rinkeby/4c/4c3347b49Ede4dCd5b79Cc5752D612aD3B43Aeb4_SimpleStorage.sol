// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    // retrieves favoriteNumber of object from People array based on their name
    mapping(string => uint256) public nameToFavoriteNumber;

    //virtual keyword makes function overrideable
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //People public person = People({favoriteNumber: 8, name: "Erno"});

    // function creates object in people array and also mapping between name and number
    // string memory means that string value will be only stored during execution of this function
    // other option would be storage to persist this data
    // calldata type is possible if you only fetch data from function
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // adds variables to People struct
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}