// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TheVault {
    mapping(string => Wallet) public wallet;
    uint8 public walletCounter;

    struct Transaction {
        uint256 date;
        uint8 value;
        address sender;
        address receiver;
    }

    struct Member {
        string firstName;
        string lastName;
        address currentAddress;
        uint8 id;
        uint8 balance;
        uint8 withdrawalLimit;
    }

    struct Wallet {
        uint8 id;
        uint creationDate;
        string name;
        uint balance;
        Transaction[] transactionHistory;
        mapping(address => Member) members;
    }

    function getWalletId(string memory walletName) public view returns (uint8) {
        return wallet[walletName].id;
    }

    function getWalletBalance(string memory walletName) public view returns (uint) {
        return wallet[walletName].balance;
    }

    function initializeWallet(string memory walletName) public payable {
        Wallet storage newWallet = wallet[walletName];
        newWallet.id = walletCounter++;
        newWallet.creationDate = block.timestamp;
        newWallet.name = walletName;
        newWallet.balance = msg.value;

      /*  for (uint i = 0; i < initialMembers.length; i++) {
            newWallet.members[initialMembers[i].currentAddress] = initialMembers[i];
        }
      */
    }
}