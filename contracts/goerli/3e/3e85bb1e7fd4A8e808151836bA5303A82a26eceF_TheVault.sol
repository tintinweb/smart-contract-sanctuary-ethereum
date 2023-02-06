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
        uint256 walletId;
        uint8 balance;
        uint8 withdrawalLimit;
    }

    struct Wallet {
        uint256 id;
        uint256 creationDate;
        string name;
        uint256 balance;
        Transaction[] transactionHistory;
        mapping(address => Member) member;
    }

    function getWalletId(string memory walletName)
        public
        view
        returns (uint256)
    {
        return wallet[walletName].id;
    }

    function getWalletBalance(string memory walletName)
        public
        view
        returns (uint256)
    {
        return wallet[walletName].balance;
    }

    function initializeWallet(
        string memory walletName,
        address[] memory membersAddresses,
        string[] memory membersFirstNames,
        string[] memory membersLastNames
    ) public payable {
        Wallet storage newWallet = wallet[walletName];
        newWallet.id = walletCounter;
        newWallet.creationDate = block.timestamp;
        newWallet.name = walletName;
        newWallet.balance = msg.value;

        for (uint256 i = 0; i < membersAddresses.length; i++) {
            Member storage newMember = newWallet.member[membersAddresses[i]];
            newMember.firstName = membersFirstNames[i];
            newMember.lastName = membersLastNames[i];
            newMember.currentAddress = membersAddresses[i];
            newMember.walletId = walletCounter;
            newMember.balance = 0;
            newMember.withdrawalLimit = 5;
        }
        walletCounter++;

        /*  for (uint i = 0; i < initialMembers.length; i++) {
            newWallet.members[initialMembers[i].currentAddress] = initialMembers[i];
        }
      */
    }
}