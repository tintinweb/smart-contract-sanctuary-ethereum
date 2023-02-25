// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract bank {
    event newBalance(string name, uint newBalance);
    struct account {
        string name;
        uint balance;
    }
    mapping(address => account) accounts;
    address public owner;
    uint id;
    mapping(address => uint) addressId;

    constructor() {
        owner = msg.sender;
    }

    // function to creat an account ;
    function creatAccount(string memory _name) public payable {
        uint balance;
        accounts[msg.sender] = account(_name, balance + msg.value);
        addressId[msg.sender] = ++id;
    }

    //function to add funds
    function addToAccount() public payable {
        require(
            addressId[msg.sender] > 0,
            "you do not have an account, please create one first!"
        );
        accounts[msg.sender].balance += msg.value;
        emit newBalance(
            accounts[msg.sender].name,
            accounts[msg.sender].balance
        );
    }

    // function to withdraw
    function withdraw(uint _amount) public {
        require(
            _amount < accounts[msg.sender].balance,
            "You can't withdraw this amount!"
        );
        accounts[msg.sender].balance -= _amount;
        payable(msg.sender).transfer(_amount);
        emit newBalance(
            accounts[msg.sender].name,
            accounts[msg.sender].balance
        );
    }

    //function check balance :
    function check(
        address _address
    ) public view returns (string memory Owner, uint Balance) {
        return (accounts[_address].name, accounts[_address].balance);
    }
}