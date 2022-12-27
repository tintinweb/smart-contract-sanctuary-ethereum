//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    struct user{
        string id;
        string pw;
        bool isLoggedIn;
    }
    mapping(address => user) Users;

    function signUp(address _addr, string memory _id, string memory _pw) public {
        Users[_addr] = user(_id, _pw, false);
    }

    function checkUser(address _addr) public view returns(bool) {
        if (keccak256(bytes(Users[_addr].id)) == keccak256(bytes('')) 
        || keccak256(bytes(Users[_addr].pw)) == keccak256(bytes(''))) return false;
        else return true;
    }

    function signIn(string memory _id, string memory _pw) public {
        require(keccak256(bytes(Users[msg.sender].id)) == keccak256(bytes(_id)) 
        || keccak256(bytes(Users[msg.sender].pw)) == keccak256(bytes(_pw)), "It doesn't match");

        Users[msg.sender].isLoggedIn = true;
    }

    function getUser(address _addr) public view returns(user memory) {
        require(msg.sender == owner, "You can't access it");
        return Users[_addr];
    }
}