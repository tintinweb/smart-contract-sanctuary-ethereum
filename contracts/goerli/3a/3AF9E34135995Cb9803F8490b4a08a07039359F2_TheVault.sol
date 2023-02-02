// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TheVault {
    mapping(uint8 => Wallet) public wallet;
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
        uint8 walletId;
        uint8 balance;
        uint8 withdrawalLimit;
    }

    struct Wallet {
        uint8 walletId;
        uint256 creationDate;
        string name;
        uint8 balance;
        Transaction[] transactionHistory;
        mapping(address => Member) members;
    }

    function getWalletNameById(uint8 walletId) public returns (string memory) {
        return wallet[walletId].name;
    }

    function initializeWallet(string memory name) public {
        Wallet storage newWallet = wallet[walletCounter];
        newWallet.walletId = walletCounter++;
        newWallet.creationDate = block.timestamp;
        newWallet.name = name;

      /*  for (uint i = 0; i < initialMembers.length; i++) {
            newWallet.members[initialMembers[i].currentAddress] = initialMembers[i];
        }
      */
    }
}