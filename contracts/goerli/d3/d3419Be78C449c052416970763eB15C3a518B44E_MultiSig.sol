/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSig {

  struct Transaction {
    address payable to;
    uint value;
    bool executed;
    uint confirmations;
  }

  // transaction index -> sender -> status
  mapping(uint => mapping(address => bool)) public isConfirmed;

  Transaction[] public transactions;
  address[] private signers;
  uint public threshold;

  modifier onlySigners() {
    bool isSigner = false;
    for (uint i = 0; i < signers.length; i++) {
      if (msg.sender == signers[i]) {
        isSigner = true;
        break;
      }
    }
    require(isSigner, "Only signers can call this function");
    _;
  }

  modifier validThreshold(uint _threshold)  {
    _;
    require(_threshold <= signers.length, "Threshold must be less than or equal to the number of signers");
  }

  modifier txExists(uint _index) {
    require(_index < transactions.length, "Transaction does not exist");
    _;
  }

  modifier txNotExecuted(uint _index) {
    require(!transactions[_index].executed, "Transaction has already been executed");
    _;
  }

  modifier txNotConfirmed(uint _index) {
    require(!isConfirmed[_index][msg.sender], "Transaction has already been confirmed by you");
    _;
  }

  modifier thresholdMet(uint _index) {
    require(transactions[_index].confirmations >= threshold, "Threshold not met");
    _;
  }

  receive() external payable {}
  
  constructor(address[] memory _signers, uint _threshold) validThreshold( _threshold) {
    threshold = _threshold;
    signers = _signers;
  }

  function getSigners() public view returns (address[] memory) {
    return signers;
  }

  function getThreshold() public view returns (uint) {
    return threshold;
  }

  function getTransaction(uint _index) public view returns (Transaction memory) {
    return transactions[_index];
  }

  function addSignerAndThreshold(address _signer, uint _threshold) public onlySigners validThreshold(_threshold) {
    signers.push(_signer);
    threshold = _threshold;
  }

  function removeSignerAndThreshold(address _signer, uint _threshold) public onlySigners validThreshold( _threshold) {
    uint index = 0;
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == _signer) {
        index = i;
        break;
      }
    }
    delete signers[index];
    signers[index] = signers[signers.length - 1];
    signers.pop();

    threshold = _threshold;
  }

  function submitTransaction(address payable _to, uint _value) public onlySigners {
    transactions.push(
      Transaction({
        to: _to,
        value: _value,
        executed: false,
        confirmations: 0
      })
    );
  }

  function confirmTransaction(uint _index) public onlySigners txExists(_index) txNotConfirmed(_index) txNotExecuted(_index) {
    Transaction storage transaction = transactions[_index];
    transaction.confirmations += 1;
    isConfirmed[_index][msg.sender] = true;
  }

  function executeTransaction(uint _index) public onlySigners txExists(_index) txNotExecuted(_index) thresholdMet(_index) {
    Transaction storage transaction = transactions[_index];
    address payable _to = transaction.to;
    (bool sent, ) = _to.call{value: transaction.value}("");
    
    require(sent, "tx failed");
    transaction.executed = sent;
  }
}