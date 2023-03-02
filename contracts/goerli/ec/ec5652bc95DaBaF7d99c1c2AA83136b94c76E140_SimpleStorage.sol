// SPDX-License-Identifier: MIT

pragma solidity >=0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameTofavoriteNumber;

    struct People {
        string fullName;
        uint256 favoriteNumber;
    }

    // Array to use struct
    People[] public people;

    // function to store a value for FAVORITENUMBER
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // function to retrieve the stored FAVORITENUMBER value
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // function to add new persons to People Array
    function addPerson(string memory _fullName, uint256 _favoriteNumber) public {
        // People memory newPerson = People({fullName: _fullName, favoriteNumber: _favoriteNumber});
        // People memory newPerson = People(_fullName, _favoriteNumber);
        // people.push(newPerson);

        people.push(People(_fullName, _favoriteNumber));
        nameTofavoriteNumber[_fullName] = _favoriteNumber;

    }
}