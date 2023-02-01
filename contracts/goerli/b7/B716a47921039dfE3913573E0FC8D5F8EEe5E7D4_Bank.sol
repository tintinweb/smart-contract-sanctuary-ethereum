pragma solidity ^0.8.9;

contract Bank {
    struct Account {
        address payable owner;
        uint256 balance;
    }

    address payable bankOwner;

    mapping(address => Account) accounts;

    constructor() {
        bankOwner = payable(msg.sender);
    }

    function createAccount() public {
        Account storage account = accounts[msg.sender];
        account.owner = payable(msg.sender);
        account.balance = 0;
    }

    function deposit(uint256 amount) public payable {
        Account storage account = accounts[msg.sender];
        (bool sent,) = bankOwner.call{value: amount}("");
        require(sent, "Deposit error");
        account.balance += amount;
    }

    function getBalance() public view returns (uint256) {
        Account storage conta = accounts[msg.sender];
        return conta.balance;
    }

    function withdraw(uint256 amount) public {
        Account storage account = accounts[msg.sender];
        require(account.balance >= amount, "Insificient Funds");
        account.balance -= amount;
        account.owner.transfer(amount);
    }
}