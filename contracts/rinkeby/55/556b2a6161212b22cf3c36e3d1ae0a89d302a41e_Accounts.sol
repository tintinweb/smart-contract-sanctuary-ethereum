/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Accounts {
    address payable owner;

    uint public no_of_accounts = 0;
    uint public total_fee = 0;

    struct Account {
        uint id;
        string accountname;
        uint balance;
        address createdby;
    }

    Account[] public accounts;

    mapping(address => Account[]) public accountToAddresses;

    modifier onlyOwner(uint _index) {
        require(msg.sender == accounts[_index].createdby, "Only account owner can perform function");
        _;
    }

    modifier enoughBalance(uint _index) {
        require(msg.value >= accounts[_index].balance, "Not enough balance");
        _;
    }

    modifier uniqueAccountName(string memory _name) {
        bool isunique = true;
        for (uint i = 0; i < no_of_accounts; i++) {
            if (keccak256(bytes(accounts[i].accountname)) == keccak256(bytes(_name))) {
                isunique = false;
            }
        }

        require(isunique == true, "Account name is not unique");
        _;
    }

    modifier accountExisted(string memory _name) {
        bool isexisted = false;
        for (uint i = 0; i < no_of_accounts; i++) {
            if (keccak256(bytes(accounts[i].accountname)) == keccak256(bytes(_name))) {
                isexisted = true;
            }
        }

        require(isexisted == true, "Account not found");
        _;
    }

    constructor() {
        no_of_accounts += 1;
        accounts.push(Account(no_of_accounts, "Account A", 0, msg.sender));
    }

    function addAccount(string memory _name) public uniqueAccountName(_name) {
        require(msg.sender != address(0));
        no_of_accounts ++;
        accounts.push(Account(no_of_accounts, _name, 0, msg.sender));
    }

    function deposit(string memory _name) public payable {
        uint index = getAccount(_name);
        accounts[index].balance += msg.value;
    }

    function withdraw(string memory _name, uint _amount) public {
        uint index = getAccount(_name);
        address payable receiver = payable(accounts[index].createdby);
        receiver.transfer(_amount);
        accounts[index].balance -= _amount;
    }

    function transfer(string memory _sendername, string memory _receivername, uint _amount) public {
        uint receiverindex = getAccount(_receivername);
        uint senderindex = getAccount(_sendername);

        if (accounts[receiverindex].createdby == msg.sender) {
            accounts[senderindex].balance -= _amount;
            accounts[receiverindex].balance += _amount;
        } else {
            uint fee = _amount * 1 / 100;
            total_fee += fee;
            uint deducted_fee_amount = _amount - fee;
            accounts[senderindex].balance -= _amount;
            accounts[receiverindex].balance += deducted_fee_amount;
        }
    }

    function allAccounts() public view returns (Account[] memory) {
        return accounts;
    }

    function getAccount(string memory _name) public accountExisted(_name) view returns (uint) {
        for (uint i = 0; i < no_of_accounts; i++) {
            if (keccak256(bytes(accounts[i].accountname)) == keccak256(bytes(_name))
                ) {
                return i;
            }
        }
        revert('Account not found');
    }

    function accountOf(address _address) public view returns(Account[] memory) {
        Account[] memory myAccounts = new Account[](no_of_accounts);
        uint j;
        for (uint i = 0; i < no_of_accounts; i++) {
            if (accounts[i].createdby == _address) {
                myAccounts[j] = accounts[i];
                j++;
            }
        }
        return myAccounts;
    }

}

// Accounts.deployed().then(function(instance) { return instance.allAccounts() })
// Accounts.deployed().then(function(instance) { return instance.addAccount("Account A") })
// Accounts.deployed().then(function(instance) { return instance.getAccount(0) })
// Accounts.deployed().then(function(instance) { return instance.deposit("Account A",{value: web3.utils.toWei("3", 'ether')}) })
// Accounts.deployed().then(function(instance) { return instance.withdraw("Account A", web3.utils.toWei("1", 'ether')) })
// Accounts.deployed().then(function(instance) { return instance.transfer("Account A", "Account B", web3.utils.toWei("1", 'ether')) })