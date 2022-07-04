//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
contract MultiSigWalletTest {

    struct Transaction {
        uint timestamp;
    }

    mapping(uint => Transaction) public  transaction;

    constructor(){
        transaction[1] = Transaction({
            timestamp: block.timestamp
        });
    }

    function getTransction() public view returns(Transaction memory) {
        return transaction[1];
    }

    function updateTransaction() external {
        Transaction storage updateValueTransaction = transaction[1];
        updateValueTransaction.timestamp = block.timestamp;
    }
   
}