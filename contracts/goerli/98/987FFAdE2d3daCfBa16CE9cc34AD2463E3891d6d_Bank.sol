// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Bank {

    struct Account {
        uint balance;
        uint lastDeposit;
    }

    mapping(address => Account) accounts;

    event etherDeposited(address indexed account, uint amount);
    event etherWithdrawed(address indexed account, uint amount);

    /// @notice Get the Balance of the last deposit
    /// @return The balance of the last Deposit
    function getBalanceAndLastDeposit() external view returns(Account memory) {
        return accounts[msg.sender];
    }

    function withdraw(uint _amount) external {
        require(accounts[msg.sender].balance >= _amount, "Not enough funds");
        accounts[msg.sender].balance -= _amount;
        (bool received, ) = msg.sender.call{value: _amount}("");
        require(received, "An error occured");
        emit etherWithdrawed(msg.sender, _amount);
    }

    function deposit() external payable {
        require(msg.value > 0, "Not enough funds deposited");
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].lastDeposit = block.timestamp;
        emit etherDeposited(msg.sender, msg.value);
    }

}