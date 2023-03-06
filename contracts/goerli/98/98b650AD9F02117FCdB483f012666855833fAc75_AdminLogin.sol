/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract AdminLogin {

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }
    
    address owner;

    struct Admin { 
        bytes32 username;
        string password;
    }
    
    Admin[] admins;

    function addAdmin(bytes32 _username, string memory _password) public isOwner returns (string memory) {
        for (uint i=0; i<admins.length; i++) {
            if (admins[i].username == _username) return "Username already exist";
        }
        
        Admin memory newUser = Admin(_username, _password);
        admins.push(newUser);
        return "Successful";
    }

    function authenticateAdmin(bytes32 _username) public isOwner view returns (string memory) {
        for (uint i=0; i<admins.length; i++) {
            if (admins[i].username == _username) return admins[i].password;
        }
        return "Invalid username";
    } 
}