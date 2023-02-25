// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //0.8.12

contract SimpleStorage {
    // data types : boolean, uint, int, address, bytes
    uint256 favoriteNumber;
    // People public person = People({favoriteNumber:2,name:"saurabh"});
    // People public person1 = People({favoriteNumber:2,name:"saurabh"});
    // People public person2 = People({favoriteNumber:2,name:"saurabh"});
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;
    // uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure dosent need gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // all are the same for pushing the data in array

        // People memory newPerson = People({
        //     favoriteNumber: _favoriteNumber,
        //     name: _name
        // });
        // People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);

        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}