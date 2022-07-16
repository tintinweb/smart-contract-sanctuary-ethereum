// I'm a comment!
// How to enable VS code to autoformat: in command palette, open Preferences: open settings (JSON)
// add comma in previous existing command line, and add below
/*    "[solidity]": {
        "editor.defaultFormatter": "NomicFoundation.hardhat-solidity"
    }
*/
//it is telling VS code to use hardhat formating (the extension installed)
//then go to command palette, open Preferences: open user settings
// search format on save, and make sure it is checked
// so from now on, sol files when saved, will auto format to default formating.

//the other way for better formating is to install Prettier - code formatter in vscode
// then in settings (JSON), add this code
/* 
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    }
*/
//and in user settings, in default formatter, select prettier code formater

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}