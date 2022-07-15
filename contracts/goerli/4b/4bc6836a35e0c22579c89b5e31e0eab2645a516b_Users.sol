/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

contract Users {

    // data structure for users, with all their information
    struct User {
        uint8 id;
        string name;
        string illnesses;
        string illnesses_description;
        address creator;
        uint age;
        uint createdAt;
        uint updatedAt;
    }

    // Mapping to the User struct and set tp public the users key
    mapping(uint256 => User) public users;

    // Used to refer to the id of a user we have in our users array
    uint8 public numUser;

    /**
     * Constructor function
     */
    constructor() {
        numUser = 1;
        addUser(
            "Government",
            "None",
            "No Description",
            0
        );
    }

    /**
    * Function to add a new user to the system.
    * @param _name           The name of the new user
    * @param _illnesses      Any illnesses that the user might have
    * @param _illnesses_description       The description of the illnesses
    * @param _age       Age of user
    */
    function addUser(
        string memory _name,
        string memory _illnesses,
        string memory _illnesses_description,
        uint _age
    ) public  {

        User storage user = users[numUser];
        user.creator = msg.sender;

        users[numUser] = User(
            numUser,
            _name,
            _illnesses,
            _illnesses_description,
            user.creator,
            _age,
            block.timestamp,
            block.timestamp
        );
        numUser++;
    }

    /**
    * Function to update an user with new information given in input
    * @param _userId        The id of the user to be searched in storage
    * @param _name           The name of the user to update
    * @param _illnesses      Any illnesses that the user might have
    * @param _illnesses_description       The description of the illnesses
    * @param _age            Age of user
    * @return _user          Returns the user and his information after update
    */
    function updateUser(
        uint256 _userId,
        string memory _name,
        string memory _illnesses,
        string memory _illnesses_description,
        uint _age
    ) public  returns (User memory){

        User storage user = users[_userId];

        user.name = _name;
        user.illnesses = _illnesses;
        user.illnesses_description = _illnesses_description;
        user.age = _age;
        user.updatedAt = block.timestamp;

        return user;
    }

    /**
    * Function to retrieve the user in question.
    * @param _userId     The id of the user to retrieve
    * @return user     Returns the requested information
    */
    function getUser(uint256 _userId) public view returns (User memory) {
        require((_userId > 0) || (_userId <= numUser), "Invalid user id");

        return users[_userId];
    }
}