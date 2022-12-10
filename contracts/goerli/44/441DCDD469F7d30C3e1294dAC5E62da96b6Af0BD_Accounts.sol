// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Roles.sol";

contract Accounts is Roleable {
    struct AccountData {
        string name;
        string email;
        string role;
        string timestamp;
        uint256 balance;
        string dob;
    }

    mapping(address => AccountData) public accounts;

    constructor() {
        owner = msg.sender;
    }

    function createAccount(
        string memory _name,
        string memory _email,
        string memory _role,
        uint256 _balance,
        string memory _dob,
        string memory _timestamp
    ) public onlyOwnerOrAdmin {
        accounts[msg.sender] = AccountData({
            name: _name,
            email: _email,
            role: _role,
            balance: _balance,
            dob: _dob,
            timestamp: _timestamp
        });
    }

    // function updateAccount(
    //     string memory _id,
    //     string memory _name,
    //     string memory _email,
    //     string memory _role,
    //     uint256 _balance,
    //     string memory _dob,
    //     string memory _timestamp
    // ) public onlyAdminOrManager {
    //     accounts[msg.sender].name = _name;
    //     accounts[msg.sender].email = _email;
    //     accounts[msg.sender].role = _role;
    //     accounts[msg.sender].balance = _balance;
    //     accounts[msg.sender].dob = _dob;
    //     accounts[msg.sender].timestamp = _timestamp;
    // }
}