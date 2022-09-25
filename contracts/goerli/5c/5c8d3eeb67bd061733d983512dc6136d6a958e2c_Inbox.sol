/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Inbox {
    string message;
    mapping(string => uint256) public nameToFavoriteNum;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // constructor(string memory initialMessage) {
    //     message = initialMessage;
    // }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }

    function addPeople(string memory _name, uint256 _favoritNumber) public {
        people.push(People(_favoritNumber, _name));
        nameToFavoriteNum[_name] = _favoritNumber;
    }
}