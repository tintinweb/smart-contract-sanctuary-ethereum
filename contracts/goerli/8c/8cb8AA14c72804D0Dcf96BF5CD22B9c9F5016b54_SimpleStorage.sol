/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // If you put no number, the default value is ZERO
    // If you don't add the public word in variables, they will keep private so you won't be able to see them
    uint256 favoriteNumber;

    // Now we have created a dictionary in wich each name will be asociated(mapped) to the number the user has set as favourite number.
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        // The keyword "virtual" its always added after the public keyword is for that any contrat that is a child from this one, can use a modified version of this function without having any compilation problem.
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // What we are doing here is in the People array push a new element using the variables as parameters
        people.push(People(_favoriteNumber, _name));
        // The line below is filtering the string in the mapping, its going to return the "FavoriteNumber" we added in the past related to the string.
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}