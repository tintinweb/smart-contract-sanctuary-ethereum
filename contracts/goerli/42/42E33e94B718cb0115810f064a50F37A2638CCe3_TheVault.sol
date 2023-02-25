// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TheVault {
    mapping(uint8 => Wallet) public wallet;
    mapping(address => uint8) public walletMemberId;
    uint8 public walletCounter;

    struct Transaction {
        uint256 date;
        uint256 value;
        address senderAddress;
        address recipientAddress;
        string txType;
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
        mapping(uint8 => Member) members;
        Transaction[] transactions;
    }

    modifier checkEthAmount(uint256 amount) {
        require(amount > 0, "The amount needs to be higher than 0");
        _;
    }

    modifier checkContractBalance(uint256 amount) {
        require(
            address(this).balance >= amount / 1e18,
            "Insufficient funds in the contract"
        );
        _;
    }

    modifier checkWalletBalance(uint256 amount) {
        require(
            wallet[walletMemberId[msg.sender]].balance >= amount / 1e18,
            "The wallet does not have enough funds"
        );
        _;
    }

    modifier checkMemberBalance(uint256 amount) {
        for (
            uint8 i = 0;
            i < wallet[walletMemberId[msg.sender]].memberCounter;
            i++
        ) {
            if (
                msg.sender ==
                wallet[walletMemberId[msg.sender]].members[i].currentAddress
            ) {
                require(
                    wallet[walletMemberId[msg.sender]].members[i].balance >=
                        amount / 1e18,
                    "You do not have enough funds"
                );
            }
        }
        _;
    }

    function withdrawMemberFunds(uint256 amount)
        public
        checkEthAmount(amount)
        checkContractBalance(amount)
        checkMemberBalance(amount)
        checkWalletBalance(amount)
    {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether to the recipient address");
        if (success) {
            wallet[walletMemberId[msg.sender]].balance -= amount / 1e18;
            for (
                uint8 i = 0;
                i < wallet[walletMemberId[msg.sender]].memberCounter;
                i++
            ) {
                if (
                    wallet[walletMemberId[msg.sender]]
                        .members[i]
                        .currentAddress == msg.sender
                ) {
                    wallet[walletMemberId[msg.sender]].members[i].balance -=
                        amount /
                        1e18;
                }
            }
            Transaction memory currentTransaction = Transaction(
                block.timestamp,
                amount / 1e18,
                msg.sender,
                msg.sender,
                "withdrawUserToUser"
            );
            wallet[walletMemberId[msg.sender]].transactions.push(
                currentTransaction
            );
        }
    }

    function sendFundsToMember(address recipientAddress)
        public
        payable
        checkEthAmount(msg.value)
    {
        wallet[walletMemberId[recipientAddress]].balance += msg.value;
        for (
            uint8 i = 0;
            i < wallet[walletMemberId[recipientAddress]].memberCounter;
            i++
        ) {
            if (
                wallet[walletMemberId[recipientAddress]]
                    .members[i]
                    .currentAddress == recipientAddress
            ) {
                wallet[walletMemberId[recipientAddress]]
                    .members[i]
                    .balance += msg.value;
            }
        }
        Transaction memory currentTransaction = Transaction(
            block.timestamp,
            msg.value,
            msg.sender,
            recipientAddress,
            "sendUserToUser"
        );
        wallet[walletMemberId[recipientAddress]].transactions.push(
            currentTransaction
        );
    }

    function sendFundsToWallet() public payable checkEthAmount(msg.value) {
        wallet[walletMemberId[msg.sender]].balance += msg.value;
        Transaction memory currentTransaction = Transaction(
            block.timestamp,
            msg.value,
            msg.sender,
            address(this),
            "sendUserToWallet"
        );
        wallet[walletMemberId[msg.sender]].transactions.push(
            currentTransaction
        );
    }

    function withdrawFundsFromWallet(uint8 amount)
        public
        checkEthAmount(amount)
        checkContractBalance(amount)
        checkWalletBalance(amount)
    {
        (bool success, ) = msg.sender.call{value: amount}("");
        if (success) {
            wallet[walletMemberId[msg.sender]].balance -= amount;
            Transaction memory currentTransaction = Transaction(
                block.timestamp,
                amount,
                address(this),
                msg.sender,
                "withdrawWalletToUser"
            );
            wallet[walletMemberId[msg.sender]].transactions.push(
                currentTransaction
            );
        }
    }

    function leaveWallet(address memberAddress)
        public
        checkMembers(memberAddress)
    {
        for (
            uint8 i = 0;
            i < wallet[walletMemberId[memberAddress]].memberCounter;
            i++
        ) {
            if (
                wallet[walletMemberId[memberAddress]]
                    .members[i]
                    .currentAddress == memberAddress
            ) {
                wallet[walletMemberId[memberAddress]].members[i] = Member(
                    "",
                    "",
                    address(0x0),
                    0,
                    0,
                    0
                );
            }
        }
        wallet[walletMemberId[memberAddress]].memberCounter--;
        walletMemberId[memberAddress] = 0;
        //Erasing the wallet if it doesn't have at least one member left
        if (wallet[walletMemberId[memberAddress]].memberCounter == 0) {
            wallet[walletMemberId[memberAddress]].id = 0;
            wallet[walletMemberId[memberAddress]].creationDate = 0;
            wallet[walletMemberId[memberAddress]].name = "";
            wallet[walletMemberId[memberAddress]].balance = 0;
            wallet[walletMemberId[memberAddress]].memberCounter = 0;
            wallet[walletMemberId[memberAddress]].ownerAddress = address(0x0);
        }
    }

    modifier checkMembers(address memberAddress) {
        require(
            wallet[walletMemberId[memberAddress]].memberCounter > 0,
            "The wallet needs to have at least 1 user"
        );
        _;
    }

    function getWalletTransactions(address memberAddress)
        public
        view
        returns (Transaction[] memory)
    {
        Transaction[] memory temporaryList = new Transaction[](
            wallet[walletMemberId[memberAddress]].transactions.length
        );

        temporaryList = wallet[walletMemberId[memberAddress]].transactions;
        return temporaryList;
    }

    function getWalletMembersBalances(address memberAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory membersBalances = new uint256[](
            wallet[walletMemberId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[walletMemberId[memberAddress]].memberCounter;
            i++
        ) {
            membersBalances[i] = wallet[walletMemberId[memberAddress]]
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
            wallet[walletMemberId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[walletMemberId[memberAddress]].memberCounter;
            i++
        ) {
            membersAddresses[i] = wallet[walletMemberId[memberAddress]]
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
            wallet[walletMemberId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[walletMemberId[memberAddress]].memberCounter;
            i++
        ) {
            membersFirstNames[i] = wallet[walletMemberId[memberAddress]]
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
            wallet[walletMemberId[memberAddress]].memberCounter
        );

        for (
            uint8 i = 0;
            i < wallet[walletMemberId[memberAddress]].memberCounter;
            i++
        ) {
            membersLastNames[i] = wallet[walletMemberId[memberAddress]]
                .members[i]
                .lastName;
        }
        return membersLastNames;
    }

    function getWalletId(address memberAddress) public view returns (uint8) {
        return walletMemberId[memberAddress];
    }

    function getWalletName(address memberAddress)
        public
        view
        returns (string memory)
    {
        return wallet[walletMemberId[memberAddress]].name;
    }

    function getWalletOwner(address memberAddress)
        public
        view
        returns (address)
    {
        return wallet[walletMemberId[memberAddress]].ownerAddress;
    }

    function getWalletBalance(address memberAddress)
        public
        view
        returns (uint256)
    {
        return wallet[walletMemberId[memberAddress]].balance;
    }

    modifier checkMemberRedundancy(
        address[] memory membersAddresses,
        uint256 memberCounter
    ) {
        require(memberCounter > 0, "A wallet needs at least one user");

        for (uint256 i = 0; i < memberCounter; i++) {
            require(
                walletMemberId[membersAddresses[i]] == 0,
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
        checkEthAmount(msg.value)
        checkMemberRedundancy(membersAddresses, membersFirstNames.length)
        checkWalletName(walletName)
        checkMemberNames(membersFirstNames, membersLastNames)
    {
        // wallet id starts with 10 instead of 0 because users with walletMemberId set to 0 do not exist yet
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

            walletMemberId[newMember.currentAddress] = newMember.walletId;
        }
        walletCounter++;
    }
}