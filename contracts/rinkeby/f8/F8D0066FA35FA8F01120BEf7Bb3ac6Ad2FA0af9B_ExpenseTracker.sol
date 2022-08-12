/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

pragma solidity ^0.6.0;

contract ExpenseTracker {
    
    int public balance = 5;
    
    Transaction[] public transaction;

    struct Transaction {
        address transactionOwner;
        string transactionDescription;
        int64 amount;
    }
    
    function addTransaction(string memory description , int64 amount) public {
        Transaction memory tx1 = Transaction(msg.sender,description,amount);
        transaction.push(tx1);
        balance += amount;
    }
    
    function transactionCount() public view returns (uint){
        return transaction.length;
    }

    function getHello() public pure returns (string memory){
        return "Hello from Contract";
    }
    
}