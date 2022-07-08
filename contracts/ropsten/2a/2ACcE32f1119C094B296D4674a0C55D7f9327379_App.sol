pragma solidity 0.8.15;

import "./Owner.sol";

contract App is Owner {

    struct User{
        string name;
        string email;
        string id;
        uint256 balance;
    }
    mapping(address => User) users;

    function setUser(User memory user) public{
        users[msg.sender] = user; 
    }

    function getUser() public view returns (User memory){
        return users[msg.sender];
    }

    function getUser(address sender) onlyOwner public view returns (User memory){
        return users[sender];
    }
}