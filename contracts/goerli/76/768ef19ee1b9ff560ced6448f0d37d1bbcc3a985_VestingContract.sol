/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.1 < 0.9.0;

contract VestingContract {
    struct Transaction {
        uint amount;
        uint duration;
        uint mode;
        uint createdAt;
    }

    uint constant cliffDuration = 30;
    uint public transactionFee;
    uint public totalAmount;
    mapping(address => Transaction) public transactions;
    mapping(address => bool) public listedAddresses;

    modifier validAddress() {
        require(msg.sender != address(0), "Address not valid.");
        _;
    }

    modifier validTransactionAddress(address _address) {
        require(_address != address(0), "Reciever address not valid.");
        _;
    }


    modifier amountCheck(uint _amount) {
        require(_amount > 0, "Amount should be grater than 0");
        _;
    }

    modifier modeCheck(uint _mode) {
        require((_mode == 1) || (_mode == 2), "Invalid mode: It could be either 1 for Referral or 2 for Manager");
        _;
    }

    function receiveAmount(address _address, uint _amount, uint _mode, uint _duration)
    payable
    external
    validAddress
    validTransactionAddress(_address)
    amountCheck(_amount)
    modeCheck(_mode)
    returns(bool){
        require(!listedAddresses[_address], "Transaction already exist");

        listedAddresses[_address] = true;
        transactions[_address] = Transaction({
            amount: _amount,
            duration: _duration,
            mode: _mode,
            createdAt: block.timestamp
        });

        uint256 fee;

        fee = _mode == 1 ? _amount/10 : _amount/5;

        totalAmount += _amount - fee;
        transactionFee += fee;

        return true;
    }

    function withdrawalAmount()
    external
    validAddress
    returns (uint) {
        Transaction memory transaction = transactions[msg.sender];
        require(listedAddresses[msg.sender], "Address does not exist.");
        require(block.timestamp > (transaction.createdAt + cliffDuration + transaction.duration), "Cliff time has not passed yet.");
        
        delete listedAddresses[msg.sender];
        delete transactions[msg.sender];

        uint256 fee;
        uint256 rewards;

        fee = transaction.mode == 1 ? transaction.amount/10 : transaction.amount/5;

        rewards = transaction.duration > 10000 ? transactionFee/5 : transactionFee/10;

        totalAmount -= transaction.amount - fee;
        transactionFee -= rewards;

        return transaction.amount - fee + rewards;
    }
}

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 1000, 1, 5