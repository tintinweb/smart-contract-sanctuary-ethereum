// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'TokenCentrol.sol';

contract UserStorage{

    address public _admin;
    MyToken public _token;
    uint32 public _iniCredit;

    struct User {
        string name;
        string contact;
        uint32 status;
    }

    mapping(address=>User) private registeredUsers;

    constructor(address admin,MyToken token,uint32 iniCredit){
        _admin = admin;
        _token= token;
        _iniCredit=iniCredit;
    }

    modifier onlyAdmin(){
        require(msg.sender == _admin, "admin required");
        _;
    }

    event RegisterUser(address indexed addr, string name, string contact);


    function getUserInfo() public{
        require(exists(msg.sender), "user is not existed");
        User memory user = registeredUsers[msg.sender];
        emit RegisterUser(msg.sender, user.name, user.contact);
    }

    function registerUser(string memory name, string memory contact) external returns(bool success) {
        require(!exists(msg.sender), "user existed");
        User storage user = registeredUsers[msg.sender];
        user.name = name;
        user.contact = contact;
        user.status=1;
        success = _token.sendUserMoneny(msg.sender,_iniCredit);
        emit RegisterUser(msg.sender, name, contact);
    }

    function getCredits(address user) external view returns(uint256) { 
        require(exists(user), "user not exists");       
        return _token.balanceOf(user);
    }

    function exists(address user) public view returns(bool) {
        return registeredUsers[user].status != 0;
    }

    function addCredits(address user, uint256 credits) public onlyAdmin {
        require(credits > 0, "credits zero");
        require(exists(user), "user not exists");
        uint256 newPoint = _token.balanceOf(user) + credits;
        require(newPoint > credits, "overflow");
        _token.sendUserMoneny(user,credits);
    }

    function subCredits(address user, uint256 credits) public onlyAdmin {
        require(credits > 0, "credits zero");
        require(exists(user), "user not exists"); 
        uint256 remand = _token.balanceOf(user);
        uint256 newPoint =  remand - credits;
        require(newPoint < remand, "overflow");
        _token.getMoneyBack(user,credits);
    }
}