/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract AdminLogin {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }
    

    struct Admin { 
        bytes32 username;
        string password;
    }
    
    Admin[] admins;

    event AdminEvent(string message);


    // Admin Authentication
    function authenticateAdmin(bytes32 _username) public isOwner
    view returns (string memory) {

        for (uint i=0; i<admins.length; i++)
            if (admins[i].username == _username) return admins[i].password;
        
        return "Invalid username";
    } 


    // Add Admin
    function validateAdmin(bytes32 _username) public isOwner
    view returns (string memory) {

        for (uint i=0; i<admins.length; i++) 
            if (admins[i].username == _username) return "Username already exist";
            
        return "Valid user";
    }

    function addAdmin(bytes32 _username, string memory _password)
    public isOwner {
        
        string memory message = validateAdmin(_username);
        if (keccak256(abi.encodePacked(message)) != keccak256(abi.encodePacked("Valid user")))
            return;

        Admin memory newUser = Admin(_username, _password);
        admins.push(newUser);

        emit AdminEvent("Successful");
    }

}