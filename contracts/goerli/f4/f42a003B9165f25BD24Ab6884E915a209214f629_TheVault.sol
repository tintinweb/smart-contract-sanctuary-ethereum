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
        // Transaction[] transactionHistory;
        mapping(uint8 => Member) members;
    }

    function leaveWallet(address memberAddress)
        public
        checkMembers(memberAddress)
    {
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
                wallet[memberWalletId[memberAddress]].members[i] = Member(
                    "",
                    "",
                    address(0x0),
                    0,
                    0,
                    0
                );
            }
        }
        wallet[memberWalletId[memberAddress]].memberCounter--;
        memberWalletId[memberAddress] = 0;
        //Erasing the wallet if it doesn't have at least one member left
        if (wallet[memberWalletId[memberAddress]].memberCounter == 0) {
            wallet[memberWalletId[memberAddress]].id = 0;
            wallet[memberWalletId[memberAddress]].creationDate = 0;
            wallet[memberWalletId[memberAddress]].name = "";
            wallet[memberWalletId[memberAddress]].balance = 0;
            wallet[memberWalletId[memberAddress]].memberCounter = 0;
            wallet[memberWalletId[memberAddress]].ownerAddress = address(0x0);
        }
    }

    modifier checkMembers(address memberAddress) {
        require(
            wallet[memberWalletId[memberAddress]].memberCounter > 0,
            "The wallet needs to have at least 1 user"
        );
        _;
    }

    function getWalletMembersBalances(address memberAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory membersBalances = new uint256[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[memberWalletId[memberAddress]].memberCounter;
            i++
        ) {
            membersBalances[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .balance;
        }
        return membersBalances;
    }

    function getWalletMembersAddresses(address memberAddress)
        public
        view
        returns (address[] memory)
    {
        address[] memory membersAddresses = new address[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[memberWalletId[memberAddress]].memberCounter;
            i++
        ) {
            membersAddresses[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .currentAddress;
        }
        return membersAddresses;
    }

    function getWalletMembersFirstNames(address memberAddress)
        public
        view
        returns (string[] memory)
    {
        string[] memory membersFirstNames = new string[](
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
        }
        return membersFirstNames;
    }

    function getWalletMembersLastNames(address memberAddress)
        public
        view
        returns (string[] memory)
    {
        string[] memory membersLastNames = new string[](
            wallet[memberWalletId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[memberWalletId[memberAddress]].memberCounter;
            i++
        ) {
            membersLastNames[i] = wallet[memberWalletId[memberAddress]]
                .members[i]
                .lastName;
        }
        return membersLastNames;
    }

    function getWalletId(address memberAddress) public view returns (uint8) {
        return memberWalletId[memberAddress];
    }

    function getWalletOwner(address memberAddress)
        public
        view
        returns (address)
    {
        return wallet[memberWalletId[memberAddress]].ownerAddress;
    }

    function getWalletBalance(address memberAddress)
        public
        view
        returns (uint256)
    {
        return wallet[memberWalletId[memberAddress]].balance;
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