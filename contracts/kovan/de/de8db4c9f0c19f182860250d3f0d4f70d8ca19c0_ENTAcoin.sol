/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ENTAcoin {

    address ENTA = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;

    struct User {
        address account;
        string name;
        uint balance;
    }

    User[] users;
    mapping(address => User) mapUser;

    struct Movement {
        address from;
        address to;
        uint date;
        uint value;
        string reason;
    }

    Movement[] movements;
    mapping(address => Movement) mapMovement;

    struct Record {
        address to;
        uint date;
        uint value;
    }

    Record[] records;
    mapping(address => Record) mapRecord;

    function addUser(address account, string memory name) public {
        require (
            msg.sender == ENTA,
            unicode"Only ENTA can register students."
        );
        mapUser[account].account = account;
        mapUser[account].name = name;
        mapUser[account].balance = 0;
        users.push(mapUser[account]);
    }

    function MonthlyTransfer(uint date) public {
        require (
            msg.sender == ENTA,
            unicode"Only ENTA can use this."
        );

        for (uint i=0; i < users.length; i++) {
            users[i].balance += 100;
            mapUser[users[i].account].balance = users[i].balance;
            mapRecord[users[i].account].to = users[i].account;
            mapRecord[users[i].account].date = date;
            mapRecord[users[i].account].value = 100;
            records.push(mapRecord[users[i].account]);
        }
    }

    function Transfer(address account, uint date, uint value, string memory reason) public {
        require (
            msg.sender == mapUser[msg.sender].account &&
            msg.sender != ENTA,
            unicode"You need to be a registered student"
        );
        require (
            account != ENTA,
            unicode"Use the Payment method."
        );
        require (
            account != msg.sender,
            unicode"You can't transfer ENTAcoins to yourself."
        );
        require (
            mapUser[msg.sender].balance >= value
        );
        mapUser[msg.sender].balance = mapUser[msg.sender].balance - value;
        mapUser[account].balance = mapUser[account].balance + value;
        mapMovement[msg.sender].from = msg.sender;
        mapMovement[msg.sender].to = account;
        mapMovement[msg.sender].date = date;
        mapMovement[msg.sender].value = value;
        mapMovement[msg.sender].reason = reason;
        movements.push(mapMovement[msg.sender]);        
    }

    function Payment(uint date, uint value, string memory reason) public {
        require (
            msg.sender == mapUser[msg.sender].account &&
            msg.sender != ENTA
        );
        require (
            mapUser[msg.sender].balance >= value
        );
        mapUser[msg.sender].balance = mapUser[msg.sender].balance - value;
        mapMovement[msg.sender].from = msg.sender;
        mapMovement[msg.sender].to = ENTA;
        mapMovement[msg.sender].date = date;
        mapMovement[msg.sender].value = value;
        mapMovement[msg.sender].reason = reason;
        movements.push(mapMovement[msg.sender]);
    }

    function checkBalance(address account) public view returns (string memory name, uint balance) {
        require (
            msg.sender == ENTA || msg.sender == account,
            unicode"You don't have permissions to check the balance of others accounts"
        );
        return (mapUser[account].name, mapUser[account].balance);
    }

    function checkMovement(uint movement) public view returns (string memory from, string memory to, uint value, uint at) {
        require(
            msg.sender == ENTA || msg.sender == movements[movement].from || msg.sender == movements[movement].to,
            unicode"You don't have any movements"
        );
        require
            (movement < movements.length,
            unicode"No movement register in that entry");
        if (movements[movement].to == ENTA ) {
            return (
                mapUser[movements[movement].from].name,
                "ENTA",
                movements[movement].value,
                movements[movement].date
            );
        }
        else {
            return (
                mapUser[movements[movement].from].name,
                mapUser[movements[movement].to].name,
                movements[movement].value,
                movements[movement].date
            );
        }
    }

    function checkRecords(uint movement) public view returns (string memory to, uint value, uint at) {
        require (
            msg.sender == ENTA,
            unicode"Only ENTA can check records."
        );
        return (
            mapUser[records[movement].to].name,
            records[movement].value,
            records[movement].date
        );
    }
}