/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SafeSend {

  struct Transaction {
    uint id;
    address from;
    address to;
    uint amount;
    uint unlockTime;
    bool completed;
    bool reverted;
  }

  uint public nextId;

  mapping(uint => Transaction) public transactionMap; //all transactions mapped to their uniqueId
  mapping(address => uint[]) public fromMap; //all transactionIds for which the "from" address is this address
  mapping(address => uint[]) public toMap; //all transactionIds for which the "to" address is this address

  constructor() {
    nextId = 0;
  }

  function sendTransaction(address aToAddress, uint aDelayTime) public payable {
    Transaction memory newTx = Transaction(nextId, msg.sender, aToAddress, msg.value, block.timestamp + aDelayTime, false, false);
    transactionMap[nextId] = newTx;
    fromMap[msg.sender].push(nextId);
    toMap[aToAddress].push(nextId);

    nextId = nextId + 1;
    emit TransactionStarted(newTx.to, newTx.from, newTx.id, newTx.amount);

  }

  function withdrawTransaction(uint aTransactionId) public {
    Transaction memory thisTx = transactionMap[aTransactionId];
    require(thisTx.completed == false, "This transaction has already been completed.");
    require(thisTx.reverted == false, "This transaction was reverted.");
    require(block.timestamp >= thisTx.unlockTime, "Transaction can't be withdrawn yet");
    require(msg.sender == thisTx.to, "Only receiver can withdraw this transaction");

    transactionMap[aTransactionId].completed = true;
    payable(thisTx.to).transfer(thisTx.amount);
    emit TransactionCompleted(thisTx.to, thisTx.from, thisTx.id, thisTx.amount);

  }

  function checkTransactionsWaitingReceiver(address aToAddress) public view returns (uint[] memory) {
    return toMap[aToAddress];
  }

  function checkTransactionsWaitingSender(address aFromAddress) public view returns (uint[] memory) {
    return fromMap[aFromAddress];
  }

  function abortTransaction(uint aTransactionId) public {
    Transaction memory thisTx = transactionMap[aTransactionId];
    require(msg.sender == thisTx.from, "Only the sender can revert a transaction.");
    require(thisTx.completed == false, "Transaction already processed.");
    require(thisTx.reverted == false, "Transaction already reverted.");

    transactionMap[aTransactionId].reverted = true;
    payable(thisTx.from).transfer(thisTx.amount);
    emit TransactionAborted(thisTx.to, thisTx.from, thisTx.id, thisTx.amount);
  }

  event TransactionStarted(address indexed aToAddress, address indexed aFromAddress, uint aId, uint aAmount);
  event TransactionCompleted(address indexed aToAddress, address indexed aFromAddress, uint aId, uint aAmount);
  event TransactionAborted(address indexed aToAddress, address indexed aFromAddress, uint aId, uint aAmount);

}