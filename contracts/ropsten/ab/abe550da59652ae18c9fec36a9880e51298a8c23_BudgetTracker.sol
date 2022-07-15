/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
contract BudgetTracker{
    address owner;
     int public balance = 1;
    
    Transaction[] public transaction;
    Transaction[] public transactionForUser;
    Transaction[] public transactionForUserByMonth;
    struct Transaction  {
        address user;
        string expenseDetail;
        string month;
        int amount;
    }
    mapping(address => Transaction) public transactionDetails;
    event transactionLogs (Transaction[] transactions);
    function addTransaction(address user,string memory description ,string memory month, int64 amount) public {
        bool isAlreadyExists = false;
         for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user &&  keccak256(bytes(transaction[i].expenseDetail)) ==  keccak256(bytes(description)) &&
               keccak256(bytes(transaction[i].month)) == keccak256(bytes(month)) ){
                  transaction[i].amount =  transaction[i].amount + amount;
                  isAlreadyExists = true;
              }
          }
        if(!isAlreadyExists){
        Transaction memory tx1 = Transaction(user,description,month,amount);
        transaction.push(tx1);
        balance += amount;
        transactionDetails[user] = tx1;
        }
       
    }
    
    function transactionCount() public view returns (uint){
        return transaction.length;
    }

    function fetchUserExpendicture(address user) public{
        delete transactionForUser;
         int total = 0;
          for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user){
                      Transaction storage tx1 =  transaction[i];
                   
                    transactionForUser.push(tx1);
                     total = total + transaction[i].amount;
              }
          }
            Transaction memory tx2 = Transaction(user,"Total Expenses","",total);
            transactionForUser.push(tx2);
            emit transactionLogs(transactionForUser);
    }

    function fetchUserExpendictureWithMonth(address user,string memory month) public {
         delete transactionForUserByMonth;
           int total = 0;
          for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user && keccak256(bytes(transaction[i].month)) == keccak256(bytes(month))){
                     Transaction storage tx1 =  transaction[i];
                    transactionForUserByMonth.push(tx1);
                     total = total + transaction[i].amount;
              }
          }
              Transaction memory tx2 = Transaction(user,"Total Expenses",month,total);
           transactionForUserByMonth.push(tx2);
            emit transactionLogs(transactionForUserByMonth);
    }
}