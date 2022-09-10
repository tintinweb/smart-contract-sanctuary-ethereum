/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // Data Types in Solidity are
    // boolean (for true or false)
    // uint (whole number which isnt positive or negative)
    // int (whole number which is positive or negative)
    // address (an address like the metamask address)
    // bytes
    // variables are used to set holders/placeholders for different values
    // E.g for the variables, bool hasFavoriteNumber(variable) = false/true; || uint256 hasFavoriteNumber(variable) = 123;
    // int256 favoriteNumber(variable) = -5/5; || string favoriteNumberInText(variable) = "Five"
    // address myaddress = 0xwdu83982d2uygd82h1ijso1u091ugd19hd198h1ii
    // bytes32 favoritesBytes = "cats"; bytes32 is the maximum byte size

    // when the variable is not set to any value like in the examples above,
    // the variables are automatically set to the null value which is 0
    // therefore the variable(favoriteNumber) below is automatically set to 0
    uint256 public favoriteNumber;
    // People public person = People({favoriteNumber: 3, name: "Jesulayomi"});

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => string) public favoriteNumberToName;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // The People[] is an array of the people object
    // The people object will be used to add/push new people objects into the People array
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure do not cost gas fees and they can't update the blockchain at all
    // view is for reading the contract and displaying the stored value
    // pure is for adding values but it  doesn't read or display values
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata means that the
    // memory is for storing data teporarily
    // storage is for storing data permanently
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // When the new people objects are pushed into the People array,
        // the People array stores each person/people variables as favoriteNumber and name
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
        favoriteNumberToName[_favoriteNumber] = _name;
    }
}