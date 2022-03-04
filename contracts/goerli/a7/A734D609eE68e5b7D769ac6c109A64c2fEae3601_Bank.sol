/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: BankAccountClonable

contract BankAccountClonable {
    uint256 public accountBalance;
    address public accountBankMaster;
    address public accountOwner;

    enum ACCOUNT_STATUS {
        ACTIVE,
        INACTIVE
    }

    ACCOUNT_STATUS public accountStatus;

    function initialize (address _bankMaster, address _owner, uint256 _balance) public {
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

// Part: CloneFactory

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// File: bank.sol

contract Bank is CloneFactory {
    BankAccountClonable[] public bankAccounts;  
    event BankAccountCreated(BankAccountClonable bankAccount);
    
    address public bankMasterAccountAddress;
    address public libraryAddress;

    constructor() {
        bankMasterAccountAddress = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(bankMasterAccountAddress == msg.sender, "Ownable: caller is not the owner");
        _;
    } 

    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        libraryAddress = _libraryAddress;
    }

    function createAccount() external returns(BankAccountClonable) {
        BankAccountClonable bankAccount;
        
        //First BankAccountClonable to be deployed will be the Implementation contract or the logic
        if (bankAccounts.length == 0) {
            bankAccount = new BankAccountClonable();   
            bankAccount.initialize(bankMasterAccountAddress, msg.sender, 0);
            bankAccounts.push(bankAccount);
            libraryAddress = address(bankAccount);

            emit BankAccountCreated(bankAccount);
            return bankAccount;       
        }

        for (uint cnt = 0; cnt < bankAccounts.length; cnt++) {
            if (bankAccounts[cnt].accountOwner() == msg.sender) {
                bankAccount = bankAccounts[cnt];
                break;
            }
        }
        if (address(bankAccount) == address(0x0000000000000000)) {
            bankAccount = BankAccountClonable(createClone(libraryAddress));   
            bankAccount.initialize(bankMasterAccountAddress, msg.sender, 0);
            bankAccounts.push(bankAccount);
            emit BankAccountCreated(bankAccount);
        }
        return bankAccount;
    }    

    function getAccount(address owner) public view returns(BankAccountClonable) {
        BankAccountClonable bankAccount;
        for (uint cnt = 0; cnt < bankAccounts.length; cnt++) {
            if (bankAccounts[cnt].accountOwner() == owner) {
                bankAccount = bankAccounts[cnt];
                break;
            }
        }
        return bankAccount;
    }

    function closeAccount() public {
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