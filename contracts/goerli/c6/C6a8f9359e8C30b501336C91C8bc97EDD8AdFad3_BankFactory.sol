// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Template used to initialize state variables
contract Bank {
    uint256 public bank_funds;
    address public owner;
    address public deployer;

    constructor(address _owner, uint256 _funds) {
        bank_funds = _funds;
        owner = _owner;
        deployer = msg.sender;
    }
}

contract BankFactory {
    // instantiate Bank contract
    Bank bank;

    //keep track of created Bank addresses in array
    Bank[] public list_of_banks;

    // function arguments are passed to the constructor of the new created contract
    function createBank(address _owner, uint256 _funds) external {
        bank = new Bank(_owner, _funds);
        list_of_banks.push(bank);
    }
}