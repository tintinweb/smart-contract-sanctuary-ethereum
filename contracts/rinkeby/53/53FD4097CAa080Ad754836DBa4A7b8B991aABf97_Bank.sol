/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Account{
        uint id;
        string _name;
        uint _balance;
        bool isValue;
}

contract Bank{
    address public owner;
    mapping (uint => Account) account;
    uint accountCount = 0;

    event Deposit(address indexed owner, string name, uint amount);
    event Withdraw(address indexed owner, string name, uint amount);

    constructor(){
        owner = msg.sender;
    }

    modifier isManager{
        require(msg.sender == owner,"Unauthorized");
        _;
    }

    function createAccount(string memory name) public isManager{
        account[accountCount] = Account(accountCount, name, 0, true);
        accountCount++;
    }

    function deposit(uint index) public payable isManager{
        require(msg.value > 0, "Please Enter Money Greater then 0");
        require(index >= 0, "index error");
        require(account[index].isValue, "not have account");

        emit Deposit(msg.sender, account[index]._name, msg.value);
        account[index]._balance += msg.value;
        
    }

    function withdraw(uint index, uint amount) public isManager{
        require(amount > 0, "Please Enter Money Greater then 0");
        require(index >= 0, "index error");
        require(account[index].isValue, "not have account");
        require(account[index]._balance >= amount, "you not have momney");

        emit Deposit(msg.sender, account[index]._name, amount);
        account[index]._balance -= amount;
        payable(owner).transfer(amount);
    }

    function transfer(uint reciver, uint sender, uint amount) public isManager{
        require(amount > 0, "Please Enter Money Greater then 0");
        require(account[sender].isValue, "not have account");
        require(account[sender]._balance >= amount, "you not have momney");

        require(account[reciver].isValue, "not have account reciver");
        account[sender]._balance -= amount;
        account[reciver]._balance += amount;

    }

    function getAccountCount() public view returns(uint){
        return accountCount;
    }

    function getAccount(uint index) public view returns(Account memory){
        return account[index];
    }
}