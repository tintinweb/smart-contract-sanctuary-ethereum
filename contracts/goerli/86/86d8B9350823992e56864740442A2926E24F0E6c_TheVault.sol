// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TheVault {
    mapping(string => Wallet) public wallet;
    mapping(address => uint256) public memberWalletId;
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
        uint256 balance;
        uint8 withdrawalLimit;
    }

    struct Wallet {
        uint256 id;
        uint256 creationDate;
        string name;
        uint256 balance;
        uint8 memberCounter;
        address ownerAddress;
        string ownerFirstName;
        string ownerLastName;
        Transaction[] transactionHistory;
        mapping(uint8 => Member) members;
    }

    function getWalletId(string memory walletName)
        public
        view
        returns (uint256)
    {
        return wallet[walletName].id;
    }

    function getWalletOwner(string memory walletName)
        public
        view
        returns (address)
    {
        return wallet[walletName].ownerAddress;
    }

    function getWalletBalance(string memory walletName)
        public
        view
        returns (uint256)
    {
        return wallet[walletName].balance;
    }

    function getWalletMemberCounter(string memory walletName)
        public
        view
        returns (uint8)
    {
        return wallet[walletName].memberCounter;
    }

    function getWalletMembers(string memory walletName)
        public
        view
        returns (string[] memory)
    {
        address[] memory membersAddresses = new address[](
            wallet[walletName].memberCounter
        );
        string[] memory membersFirstNames = new string[](
            wallet[walletName].memberCounter
        );
        string[] memory membersLastNames = new string[](
            wallet[walletName].memberCounter
        );
        for (uint8 i = 0; i < wallet[walletName].memberCounter; i++) {
            membersFirstNames[i] = wallet[walletName].members[i].firstName;
            membersLastNames[i] = wallet[walletName].members[i].lastName;
            membersAddresses[i] = wallet[walletName].members[i].currentAddress;
        }
        return membersFirstNames;
    }

    modifier checkMemberRedundancy(
        address[] memory membersAddresses,
        uint256 memberCounter
    ) {
        require(memberCounter > 0, "A wallet needs at least one user");

        for (uint256 i = 0; i < memberCounter; i++) {
            require(
                memberWalletId[membersAddresses[i]] == 0,
                "One or more users have already joined another wallet"
            );
            for (uint256 j = 0; j < i; j++) {
                revert("The wallet can not have duplicate addresses");
            }
        }
        _;
    }

    modifier checkMemberNames(
        string[] memory membersFirstNames,
        string[] memory membersLastNames
    ) {
        require(
            membersFirstNames.length == membersLastNames.length &&
                membersFirstNames.length != 0,
            "The users need to have both first and last names"
        );
        for (uint256 i = 0; i < membersFirstNames.length; i++) {
            require(
                bytes(membersFirstNames[i]).length != 0 &&
                    bytes(membersLastNames[i]).length != 0,
                "The users need to have both first and last names"
            );
        }
        _;
    }

    modifier checkWalletName(string memory walletName) {
        require(bytes(walletName).length != 0, "The wallet needs a name");
        require(wallet[walletName].id == 0, "A wallet already has this name");
        _;
    }

    function initializeWallet(
        string memory walletName,
        address[] memory membersAddresses,
        string[] memory membersFirstNames,
        string[] memory membersLastNames
    )
        public
        payable
        checkMemberRedundancy(membersAddresses, membersFirstNames.length)
        checkWalletName(walletName)
        checkMemberNames(membersFirstNames, membersLastNames)
    {
        // wallet id starts with 100 instead of 0 because users with memberWalletId set to 0 do not exist yet
        Wallet storage newWallet = wallet[walletName];
        newWallet.id = walletCounter + 100;
        newWallet.creationDate = block.timestamp;
        newWallet.name = walletName;
        newWallet.balance = msg.value;
        newWallet.ownerAddress = membersAddresses[0];
        newWallet.ownerFirstName = membersFirstNames[0];
        newWallet.ownerLastName = membersLastNames[0];

        for (uint8 i = 0; i < membersAddresses.length; i++) {
            Member storage newMember = newWallet.members[i];
            newMember.firstName = membersFirstNames[i];
            newMember.lastName = membersLastNames[i];
            newMember.currentAddress = membersAddresses[i];
            newMember.walletId = walletCounter + 100;
            newMember.balance = 0;
            newMember.withdrawalLimit = 5;
            newWallet.memberCounter++;

            memberWalletId[newMember.currentAddress] = newMember.walletId;
        }
        walletCounter++;
    }
}