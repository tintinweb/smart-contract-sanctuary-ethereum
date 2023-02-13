// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TheVault {
    mapping(uint8 => Wallet) public wallet;
    mapping(address => uint8) public memberWalletId;
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
        uint256 balance;
        uint8 withdrawalLimit;
    }

    struct Wallet {
        uint8 id;
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

    function leaveWallet(address memberAddress) public {
        for (
            uint8 i = 0;
            i < wallet[memberWalletId[memberAddress]].memberCounter;
            i++
        ) {
            if (
                wallet[memberWalletId[memberAddress]]
                    .members[i]
                    .currentAddress == memberAddress
            ) {
                wallet[memberWalletId[memberAddress]].members[i].firstName = "";
                wallet[memberWalletId[memberAddress]].members[i].lastName = "";
                wallet[memberWalletId[memberAddress]]
                    .members[i]
                    .currentAddress = address(0x0);
                wallet[memberWalletId[memberAddress]].members[i].walletId = 0;
                wallet[memberWalletId[memberAddress]].members[i].balance = 0;
                wallet[memberWalletId[memberAddress]]
                    .members[i]
                    .withdrawalLimit = 0;
            }
        }
        wallet[memberWalletId[memberAddress]].memberCounter--;
        memberWalletId[memberAddress] = 0;
    }

    function getWalletData(address memberAddress)
        public
        view
        returns (
            uint8,
            address,
            uint256,
            address[] memory,
            string[] memory,
            string[] memory
        )
    {
        address[] memory membersAddresses = new address[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );
        string[] memory membersFirstNames = new string[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );
        string[] memory membersLastNames = new string[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );
        for (
            uint8 i = 0;
            i < wallet[memberWalletId[memberAddress]].memberCounter;
            i++
        ) {
            membersFirstNames[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .firstName;
            membersLastNames[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .lastName;
            membersAddresses[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .currentAddress;
        }
        return (
            memberWalletId[memberAddress],
            wallet[memberWalletId[memberAddress]].ownerAddress,
            wallet[memberWalletId[memberAddress]].balance,
            membersAddresses,
            membersFirstNames,
            membersLastNames
        );
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
                require(
                    membersAddresses[i] != membersAddresses[j],
                    "The wallet can not have duplicate addresses"
                );
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
        // wallet id starts with 10 instead of 0 because users with memberWalletId set to 0 do not exist yet
        Wallet storage newWallet = wallet[walletCounter + 10];
        newWallet.id = walletCounter + 10;
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
            newMember.walletId = walletCounter + 10;
            newMember.balance = 0;
            newMember.withdrawalLimit = 5;
            newWallet.memberCounter++;

            memberWalletId[newMember.currentAddress] = newMember.walletId;
        }
        walletCounter++;
    }
}