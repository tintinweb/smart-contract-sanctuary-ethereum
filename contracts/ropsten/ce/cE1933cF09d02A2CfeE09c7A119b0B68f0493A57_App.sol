pragma solidity 0.8.15;

import "./Owner.sol";

contract App is Owner {
    address public sender;
    struct User{
        string name;
        string email;
        string id;
        uint256 balance;
    }
    mapping(address => User) public users;

    function setUser(User memory user) public{
        sender = msg.sender;
        users[sender].name = user.name;
        users[sender].email = user.email;
        users[sender].id = user.id;
        users[sender].balance = user.balance;
    }

    function getUser() public view returns (User memory){
        return users[msg.sender];
    }

    function getUser(address _sender) onlyOwner public view returns (User memory){
        return users[_sender];
    }

    function getSender() public view returns (address){
        return msg.sender;
    }
}