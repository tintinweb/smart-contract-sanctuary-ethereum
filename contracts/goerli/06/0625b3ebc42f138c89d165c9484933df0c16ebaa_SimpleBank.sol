/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SimpleBank {
    address bankOwner;
    uint256 bankBalance;

    struct Account {
        address owner;
        string name;
        uint256 balance;
    }

    mapping(address => string[]) userAccounts;
    mapping(string => Account) accounts;
    mapping(string => bool) isAccountNameExist;

    constructor() {
        bankOwner = msg.sender;
        bankBalance = 0;
    }

    event AddAccountEvent(address _user, string _name);
    event DepositEvent(address _from, string _to, uint256 _amount);
    event WithdrawnEvent(string _from, address _to, uint256 _amount);
    event TransferAmountEvent(string _from, string _to, uint256 _amount);
    event withdrawnBankBalanceEvent(uint256 _amount);

    function addAccount(string memory _name) public {
        require(
            isAccountNameExist[_name] == false,
            "add_account_fail_name_exist"
        );
        accounts[_name] = Account(msg.sender, _name, 0);
        userAccounts[msg.sender].push(_name);
        isAccountNameExist[_name] = true;
        emit AddAccountEvent(msg.sender, _name);
    }

    function deposit(string memory _name) public payable {
        require(
            isAccountNameExist[_name] == true,
            "deposit_fail_name_not_exist"
        );
        require(msg.value > 0, "deposit_fail_value_zero");
        accounts[_name].balance += msg.value;
        emit DepositEvent(msg.sender, _name, msg.value);
    }

    function withdrawn(string memory _name, uint256 _amount) public {
        require(
            isAccountNameExist[_name] == true,
            "withdrawn_fail_name_not_exist"
        );
        require(
            accounts[_name].owner == msg.sender,
            "withdrawn_fail_not_owner"
        );
        require(_amount > 0, "withdrawn_fail_value_zero");
        require(
            accounts[_name].balance >= _amount,
            "withdrawn_fail_balance_not_enough"
        );
        accounts[_name].balance -= _amount;
        payable(msg.sender).transfer(_amount);
        emit WithdrawnEvent(_name, msg.sender, _amount);
    }

    function transferAmount(
        string memory _from,
        string memory _to,
        uint256 _amount
    ) public {
        require(
            isAccountNameExist[_from] == true,
            "transfer_fail_from_name_not_exist"
        );
        require(
            isAccountNameExist[_to] == true,
            "transfer_fail_to_name_not_exist"
        );
        require(
            accounts[_from].owner == msg.sender,
            "transfer_fail_from_not_owner"
        );
        require(_amount >= 100, "transfer_fail_value_less_than_100");
        require(
            accounts[_from].balance >= _amount,
            "transfer_fail_from_balance_not_enough"
        );
        if (accounts[_from].owner != accounts[_to].owner) {
            uint256 fee = _amount / 100;
            bankBalance += fee;
            accounts[_from].balance -= _amount;
            accounts[_to].balance += (_amount - fee);
            emit TransferAmountEvent(_from, _to, _amount - fee);
        } else {
            accounts[_from].balance -= _amount;
            accounts[_to].balance += _amount;
            emit TransferAmountEvent(_from, _to, _amount);
        }
    }

    function withdrawnBankBalance(uint256 _amount) public {
        require(bankOwner == msg.sender, "withdrawn_bank_fail_not_owner");
        require(_amount > 0, "withdrawn_bank_fail_value_zero");
        require(bankBalance >= _amount, "withdrawn_bank_fail_balance_not_enough");
        bankBalance -= _amount;
        payable(msg.sender).transfer(_amount);
        emit withdrawnBankBalanceEvent(_amount);
    }

    function transferAmountList(
        string memory _from,
        string[] memory _tos,
        uint256 _amount
    ) public {
        require(
            isAccountNameExist[_from] == true,
            "transfer_fail_from_name_not_exist"
        );
        require(
            accounts[_from].owner == msg.sender,
            "transfer_fail_from_not_owner"
        );
        require(_amount >= 100, "transfer_fail_value_less_than_100");
        require(
            accounts[_from].balance >= _amount * _tos.length,
            "transfer_fail_from_balance_not_enough"
        );
        for (uint256 i = 0; i < _tos.length; i++) {
            require(
                isAccountNameExist[_tos[i]] == true,
                "transfer_fail_to_name_not_exist"
            );
            if (accounts[_from].owner != accounts[_tos[i]].owner) {
                uint256 fee = _amount / 100;
                bankBalance += fee;
                accounts[_from].balance -= _amount;
                accounts[_tos[i]].balance += (_amount - fee);
                emit TransferAmountEvent(_from, _tos[i], _amount - fee);
            } else {
                accounts[_from].balance -= _amount;
                accounts[_tos[i]].balance += _amount;
                emit TransferAmountEvent(_from, _tos[i], _amount);
            }
        }
    }

    function getOwnerByName(string memory _name)
        public
        view
        returns (address)
    {
        return accounts[_name].owner;
    }

    function getBalanceByName(string memory _name)
        public
        view
        returns (uint256)
    {
        return accounts[_name].balance;
    }

    function getUserAccounts() public view returns (string[] memory) {
        return userAccounts[msg.sender];
    }

    function getBankOwner() public view returns (address) {
        return bankOwner;
    }

    function getBankBalance() public view returns (uint256) {
        return bankBalance;
    }
}