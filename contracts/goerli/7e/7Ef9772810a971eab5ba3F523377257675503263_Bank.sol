/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: BankAccount

contract BankAccount {
    uint256 public accountBalance;
    address public accountBankMaster;
    address public accountOwner;

    enum ACCOUNT_STATUS {
        ACTIVE,
        INACTIVE
    }

    ACCOUNT_STATUS public accountStatus;

    constructor(address _bankMaster, address _owner, uint256 _balance) public {
        accountBankMaster = _bankMaster;
        accountOwner = _owner;
        accountBalance = _balance;
        accountStatus = ACCOUNT_STATUS.ACTIVE;
    }    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(accountOwner == msg.sender, "Ownable: caller is not the owner");
        _;
    }  

    /**
     * @dev Throws if called by any account other than the bankMaster.
     */
    modifier onlyBankMaster() {
        require(accountBankMaster == msg.sender, "Ownable: caller is not the bank master");
        _;
    }  

    function deposit() onlyOwner payable public returns(uint256){
        if (msg.value > 0) {
            accountBalance += msg.value;
            (bool success, ) = accountBankMaster.call{value: msg.value}("");
            //_bankMasterAccountAddress.transfer(msg.value);
            require(success, "Deposit failed.");
        }

        return accountBalance;
    }

    function withdraw() onlyBankMaster payable public returns(uint256) {
        if (msg.value <= accountBalance) {
            accountBalance -= msg.value;

            (bool success, ) = accountOwner.call{value: msg.value}("");
            require(success, "Deposit failed.");        
        }

        return accountBalance;
    }
}

// File: bank.sol

contract Bank {
    BankAccount[] public bankAccounts;  
    address public bankMasterAccountAddress;

    constructor() public {
        bankMasterAccountAddress = msg.sender;
    }

    function createAccount() public returns(BankAccount) {
        BankAccount bankAccount;
        for (uint cnt = 0; cnt < bankAccounts.length; cnt++) {
            if (bankAccounts[cnt].accountOwner() == msg.sender) {
                bankAccount = bankAccounts[cnt];
                break;
            }
        }
        if (address(bankAccount) == address(0x0000000000000000)) {
            bankAccount = new BankAccount(bankMasterAccountAddress, msg.sender, 0);   
            bankAccounts.push(bankAccount);
        }
        return bankAccount;
    }    

    function getAccount(address owner) public view returns(BankAccount) {
        BankAccount bankAccount;
        for (uint cnt = 0; cnt < bankAccounts.length; cnt++) {
            if (bankAccounts[cnt].accountOwner() == owner) {
                bankAccount = bankAccounts[cnt];
                break;
            }
        }
        return bankAccount;
    }

    function closeAccount() public {        
        BankAccount bankAccount;
        for (uint cnt = 0; cnt < bankAccounts.length; cnt++) {
            if (bankAccounts[cnt].accountOwner() == msg.sender && bankAccounts[cnt].accountBalance() == 0) {
                for (uint index = cnt; index < (bankAccounts.length-1); index++) {
                    bankAccounts[index] = bankAccounts[index+1];
                }
                bankAccounts.pop();
                break;
            }
        }
    }

    function getAccountCount() public view returns(uint256) {
        return bankAccounts.length;
    }
}