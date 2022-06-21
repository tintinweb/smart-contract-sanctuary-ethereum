// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract dBank {
    struct Account {
        string name;
        uint phoneNumber;
        uint balance;
    }

    struct Deposit {
        uint amount;
        string depositType;
    }

    mapping(address => Deposit[]) addressToDeposits;
    mapping(address => Account) addressToAccount;

    modifier hasAmount(uint withdrawAmount) {
        require(addressToAccount[msg.sender].balance >= withdrawAmount);
        _;
    }
    modifier hasAccount() {
        require(addressToAccount[msg.sender].phoneNumber != 0);
        _;
    }
    modifier hasNoAccount() {
        require(
            addressToAccount[msg.sender].phoneNumber == 0,
            "Account already exist!!"
        );
        _;
    }

    function balance() public view hasAccount returns (uint) {
        return addressToAccount[msg.sender].balance;
    }

    function openAccount(string memory _name, uint _phoneNumber)
        public
        hasNoAccount
    {
        Account memory newAccount = Account(_name, _phoneNumber, 0);
        addressToAccount[msg.sender] = newAccount;
    }

    function deposit(string memory _depositType) public payable hasAccount {
        addressToAccount[msg.sender].balance += msg.value;
        Deposit memory newDeposit = Deposit({
            amount: msg.value,
            depositType: getDepositType(_depositType)
        });
        addressToDeposits[msg.sender].push(newDeposit);
    }

    function withdraw(uint withdrawAmount)
        public
        payable
        hasAmount(withdrawAmount)
    {
        address payable withdrawer = payable(msg.sender);
        withdrawer.transfer(withdrawAmount);
        addressToAccount[msg.sender].balance -= withdrawAmount;
    }

    function getDepositType(string memory accountType)
        private
        pure
        returns (string memory)
    {
        bytes32 atHash = keccak256(abi.encodePacked(accountType));
        bytes32 fixedHash = keccak256(abi.encodePacked("fixed"));
        bytes32 currentHash = keccak256(abi.encodePacked("current"));

        if (atHash == fixedHash) return "fixed";
        if (atHash == currentHash) return "current";
        revert();
    }
}