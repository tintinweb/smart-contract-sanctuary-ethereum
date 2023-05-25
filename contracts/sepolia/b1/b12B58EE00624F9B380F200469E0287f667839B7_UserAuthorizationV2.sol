// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Smart Contract to store the privileges of those users that can create Sculpture Records and updates
contract UserAuthorizationV2 {
    // Enum for different privilege levels
    enum PrivilegeLevel {
        NONE,
        USER,
        ADMIN
    }

    // Count the number of admin users
    uint256 public numOfAdmins;

    // Mapping from user address to privilege level
    mapping(address user => PrivilegeLevel role) usersRoles;

    // Event for logging user authorization
    event UserAuthorized(address indexed userAddress, string privilegeLevel);

    // Event for logging privilege modifications
    event UserPrivilegeUpdated(
        address indexed userAddress,
        string newPrivilegeLevel
    );

    // Event for logging user deletion
    event UserRemoved(address indexed userAddress, string info);

    constructor() {
        // Increse the number of admins
        numOfAdmins++;

        // Add this user that deploys this contract with Admin privileges
        usersRoles[msg.sender] = PrivilegeLevel.ADMIN;
    }

    modifier isAdmin() {
        require(
            usersRoles[msg.sender] == PrivilegeLevel.ADMIN,
            "You are not authorized to perform this action!"
        );
        _;
    }

    modifier isPrivilegeValid(uint8 _privilege) {
        require(
            _privilege >= uint8(PrivilegeLevel.NONE) &&
                _privilege <= uint8(PrivilegeLevel.ADMIN),
            "Invalid Privilege value"
        );
        _;
    }

    modifier isUser(address _userAddress) {
        // Checks if the user exists
        require(
            usersRoles[_userAddress] != PrivilegeLevel.NONE,
            "The user does not exist!"
        );
        _;
    }

    // Authorizes a new user
    function authorizeUser(
        address _userAddress,
        uint8 _privilegeLevel
    ) public isAdmin isPrivilegeValid(_privilegeLevel) {
        PrivilegeLevel privilegeLevel = PrivilegeLevel(_privilegeLevel);

        // Check if the privilege to be set is not NONE
        require(
            privilegeLevel != PrivilegeLevel.NONE,
            "Setting privilege to None is the same as not authorizing the user"
        );

        // Checks if the user is not already registered
        require(
            usersRoles[_userAddress] == PrivilegeLevel.NONE,
            "User is already created and authorized"
        );

        if (privilegeLevel == PrivilegeLevel.ADMIN) {
            numOfAdmins++;
        }

        // Stores the user privilege
        usersRoles[_userAddress] = privilegeLevel;

        // Emits the event for logging the user authorization
        emit UserAuthorized(
            _userAddress,
            getPrivilegeAsString(_privilegeLevel)
        );
    }

    // Changes the user privileges
    function changeUserPrivilege(
        address _userAddress,
        uint8 _newPrivilegeLevel
    ) public isAdmin isUser(_userAddress) isPrivilegeValid(_newPrivilegeLevel) {
        PrivilegeLevel newLevel = PrivilegeLevel(_newPrivilegeLevel);

        require(
            newLevel != usersRoles[_userAddress],
            "Action reverted since the user has already the new privilege level"
        );

        if (newLevel == PrivilegeLevel.ADMIN) {
            numOfAdmins++;
        } else if (usersRoles[_userAddress] == PrivilegeLevel.ADMIN) {
            require(
                numOfAdmins > 1,
                "This admin cannot reduce its privileges since there must be at least one Admin user"
            );
            numOfAdmins--;
        }

        // Stores the new Privilege level
        usersRoles[_userAddress] = newLevel;

        // Emits the event for logging the user authorization
        emit UserPrivilegeUpdated(
            _userAddress,
            getPrivilegeAsString(_newPrivilegeLevel)
        );
    }

    // Removes an Authorized User
    function removeAuthorizedUser(
        address _userAddress
    ) public isAdmin isUser(_userAddress) {
        if (usersRoles[_userAddress] == PrivilegeLevel.ADMIN) {
            require(
                numOfAdmins > 1,
                "This admin cannot reduce its privileges since there must be at least one Admin user"
            );
            numOfAdmins--;
        }

        // Removes the user privileges
        delete usersRoles[_userAddress];

        // Emits the event for logging the user removal
        emit UserRemoved(_userAddress, "Authorized user removed!");
    }

    // Checks if a user has the minimum privileges to create a Record
    function isAuthorizedToCreate(
        address _userAddress
    ) public view returns (bool) {
        return usersRoles[_userAddress] == PrivilegeLevel.ADMIN;
    }

    // Check if a user is an Admin
    function isUserAdmin (
        address _userAddress
    ) public view returns (bool) {
        return isAuthorizedToCreate(_userAddress);
    }

    // Checks if a user has the minimum privileges to update a Record
    function isAuthorizedToUpdate(
        address _userAddress
    ) public view returns (bool) {
        return usersRoles[_userAddress] >= PrivilegeLevel.USER;
    }

    // Checks if a user is registered
    function isUserRegistered(
        address _userAddress
    ) public view returns (bool) {
        return isAuthorizedToUpdate(_userAddress);
    }

    function getPrivilegeAsString(
        uint8 _privilege
    ) private pure returns (string memory) {
        PrivilegeLevel privilegeLevel = PrivilegeLevel(_privilege);

        if (privilegeLevel == PrivilegeLevel.NONE) {
            return "User without any privileges";
        } else if (privilegeLevel == PrivilegeLevel.USER) {
            return "User with privileges to update an existing record";
        } else if (privilegeLevel == PrivilegeLevel.ADMIN) {
            return "User with privileges to create or update records";
        }

        return "Invalid Privilege Level";
    }
}