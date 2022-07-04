/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // compiling

contract SimpleStorage {
    uint256 favoriteNumber; // solidity initializes uint256 with 0: favoriteNumber = 0

    //uint256[] public favoriteNumbersList;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // function gets variable "_favoriteNumber"
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // create a new array entry "People()" in the "people" array - same as writing
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);

        // short version is
        people.push(People(_favoriteNumber, _name));

        // add the new person to the mapping, the "index-table" to find the person's favorite number by searching for theperson's name
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}