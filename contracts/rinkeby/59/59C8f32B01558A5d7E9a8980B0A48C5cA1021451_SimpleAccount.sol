//This is a simple banking system , with multiple user accounts
// User can store money in their accounts and view the balance

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleAccount {
    uint256 amountFund;
    //accounts
    struct Account {
        uint256 amountFund;
        string username;
    }

    Account[] public account;

    mapping(string => uint256) public userToFund;

    //deposit
    function deposit(uint256 _fund) public {
        amountFund = _fund;
    }

    //withdraw
    function withdraw() public view returns (uint256) {
        return amountFund;
    }

    //addAccount
    function addAccount(string memory _username, uint256 _amountFund) public {
        account.push(Account(_amountFund, _username));
        userToFund[_username] = _amountFund;
    }
}