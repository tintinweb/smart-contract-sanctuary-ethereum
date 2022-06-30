//  SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber; // Default initialization with zero value

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people; //Array of People Struct

    // Stores favourite number
    // Using `virtual` to make the function overridable by child contract
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // Retrieves favourite number
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // Adds new People struct data to the array and mapping
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}