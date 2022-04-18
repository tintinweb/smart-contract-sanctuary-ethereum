// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'TokenCentrol.sol';

contract UserCenter{

    address public _admin;
    BKCToken public _token;

    struct User {
        string name;
        string contact;
        uint32 status;
    }

    mapping(address=>User) private registeredUsers;

    constructor(address admin,BKCToken token){
        _admin = admin;
        _token= token;
    }

    modifier onlyAdmin(){
        require(msg.sender == _admin, "admin required");
        _;
    }

    event RegisterUser(address indexed addr, string name, string contact);
    event ChangeUserInfo(address indexed addr, string name, string contact);

    function registerUser(string memory name, string memory contact) external  returns(bool success) {
        require(!exists(msg.sender), "user existed");
        User storage user = registeredUsers[msg.sender];
        user.name = name;
        user.contact = contact;
        user.status=1;
        emit RegisterUser(msg.sender, name, contact);
        success =true;
    }

     function activateUser(address user) external onlyAdmin returns(bool success) {
        User storage users = registeredUsers[user];
        users.status=2;
        return true;
    }

    function getUserInfo(address adduser) public view returns(string memory name , string memory contact,uint32  status) {
        require(exists(adduser), "user is not existed");
        User memory user = registeredUsers[adduser];
        name = user.name ;
        contact = user.contact;
        status = user.status;
        return (name,contact,status);
    }

   
    function changeUserInfo(string memory name, string memory contact) external returns(bool success){
        require(exists(msg.sender), "user is not existed");
        registeredUsers[msg.sender].name = name;
        registeredUsers[msg.sender].contact=contact;
        emit ChangeUserInfo(msg.sender, name, contact);
        return true;
    }


    function exists(address user) public view returns(bool) {
        return registeredUsers[user].status != 0;
    }

    function activated(address user) public view returns(bool) {
        return registeredUsers[user].status == 2;
    }


}