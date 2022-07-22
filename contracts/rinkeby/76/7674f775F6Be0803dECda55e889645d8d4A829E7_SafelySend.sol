/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SafelySend {

  struct Transaction {
    uint sentTime;
    address from;
    address to;
    uint amount;
    uint unlockTime;
    bool done;
  }

  uint public nextId;
  address public owner;
  uint public accumTips;
  mapping(uint => Transaction) public transactionMap; //all transactions mapped to their uniqueId
  mapping(address => uint[]) public fromMap; //all transactionIds for which the "from" address is this address
  mapping(address => uint[]) public toMap; //all transactionIds for which the "to" address is this address

  constructor() {
    nextId = 0;
    accumTips = 0;
    owner = msg.sender;
  }

  function sendTransaction(address aToAddress, uint aDelayTime, uint aTip) public payable {
    uint transactionVal = msg.value - aTip;
    uint activeTime = block.timestamp + aDelayTime;
    require(transactionVal <= msg.value, "overflow error");
    require(activeTime >= block.timestamp, "overflow error");

    Transaction memory newTx = Transaction(block.timestamp, msg.sender, aToAddress, transactionVal, activeTime, false);
    transactionMap[nextId] = newTx;
    fromMap[msg.sender].push(nextId);
    toMap[aToAddress].push(nextId);

    accumTips = accumTips + aTip;
    nextId = nextId + 1;
  }

  function withdrawTransaction(uint aTransactionId) public {
    Transaction memory thisTx = transactionMap[aTransactionId];
    require(thisTx.done == false, "This transaction has already been completed.");
    require(block.timestamp >= thisTx.unlockTime, "Transaction can't be withdrawn yet");
    require(msg.sender == thisTx.to, "Only receiver can withdraw this transaction");

    transactionMap[aTransactionId].done = true;
    payable(thisTx.to).transfer(thisTx.amount);
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
    require(thisTx.done == false, "Transaction already processed.");

    transactionMap[aTransactionId].done = true;
    payable(thisTx.from).transfer(thisTx.amount);
  }

  function withdrawTips() public {
    require(msg.sender == owner, "Only owner can withdraw tips");
    uint temp = accumTips;
    accumTips = 0;
    payable(owner).transfer(temp);
  }

  function transferOwner(address newOwner) public {
    require(msg.sender == owner, "only owner can change owner");
    require(newOwner != address(0), "don't set owner to null address");
    owner = newOwner;
  }
}