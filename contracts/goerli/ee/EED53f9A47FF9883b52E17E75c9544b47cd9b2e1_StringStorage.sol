/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
Write a smart contract in Solidity that uses a mapping data structure to store user information, including their name and age. The contract should have the following functions:
addUser: A user can add their information to the mapping by calling this function and providing their name and age as arguments.

getUser: A user can retrieve their information from the mapping by calling this function and providing their name as an argument.

getAge: A user can retrieve their age from the mapping by calling this function and providing their name as an argument.
*/
contract StringStorage
{
     struct UserData {
        uint age;
        string country;
        bool married;
        bool hasValue;
    }
    address public owner ;
    constructor(){
        owner=msg.sender;
    }
    mapping(string =>UserData) private data;

    function addUser(string memory username, uint  age ,string memory country ,bool married ) public {
        require(msg.sender==owner);
        data[username]=UserData(age,country,married,true);
    }

    function getUserInfo(string memory username) public view returns( UserData memory result)
    {
        require(data[username].hasValue,"The user doesn't exist");
        return data[username];
        }
}