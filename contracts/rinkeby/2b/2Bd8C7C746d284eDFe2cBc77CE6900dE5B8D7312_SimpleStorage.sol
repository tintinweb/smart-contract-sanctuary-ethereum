// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    // favoriteNumber is a storage variable
    uint256 favoriteNumber; // Default value is null or 0

    mapping(string => uint256) public nameToFavoriteNumber; // like a dictionary

    struct People {
        // People is now a new data type like string or int
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people; // people is an array, where push is used to append to the array

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure does not spend gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Calldata, memory, storage variables
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}