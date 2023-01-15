/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Managed {
  mapping(address => bool) public managers;
  modifier onlyManagers() {
    require(managers[msg.sender] == true, "Caller is not manager");
    _;
  }
  constructor() {
    managers[msg.sender] = true;
  }
  function setManager(address _wallet, bool _manager) public onlyManagers {
    require(_wallet != msg.sender, "Not allowed");
    managers[_wallet] = _manager;
  }
}

contract NFTBridgeLog is Managed {

  event IncomingTX (address indexed wallet, uint256 logId);
  event OutgoingTX (address indexed wallet, uint256 logId);

  struct OutgoingLog {
    address wallet;
    uint256 assetId;
    uint256 date;
    uint256 chainID;
    uint256 bridgeIndex;
  }

  struct IncomingLog {
    bool minted;
    address wallet;
    uint256 assetId;
    uint256 date;
    uint256 chainID;
    uint256 logIndex;
  }

  mapping(uint256 => OutgoingLog) outgoingTx;
  mapping(uint256 => IncomingLog) incomingTx;
  mapping(bytes32 => uint256) public withdrawals;
  mapping(address => bool) public loggers;
  uint256 public outgoingIndex;
  uint256 public incomingIndex;

  constructor() {
    managers[0x00d6E1038564047244Ad37080E2d695924F8515B] = true;
  }

  function setLogger(address _logger, bool _canLog) public onlyManagers {
    loggers[_logger] = _canLog;
  }

  function outgoing(address _wallet, uint256 _assetId, uint256 _chainID, uint256 _bridgeIndex) public {
    require(loggers[msg.sender] == true, "Invalid caller");
    outgoingIndex += 1;
    OutgoingLog memory _outgoing = OutgoingLog(_wallet, _assetId, block.timestamp, _chainID, _bridgeIndex);
    outgoingTx[outgoingIndex] = _outgoing;
    emit OutgoingTX(_wallet, outgoingIndex);
  }

  function incoming(address _wallet, uint256 _assetId, uint256 _chainID, uint256 _logIndex, bytes32 txHash, bool _minted) public {
    require(loggers[msg.sender] == true, "Invalid caller");
    require(!withdrawalCompleted(txHash), "Withdrawal already completed");
    incomingIndex += 1;
    IncomingLog memory _incoming = IncomingLog(_minted, _wallet, _assetId, block.timestamp, _chainID, _logIndex);
    incomingTx[incomingIndex] = _incoming;
    withdrawals[txHash] = incomingIndex;
    emit IncomingTX(_wallet, incomingIndex);
  }

  function getIncomingTx(uint256 _index) public view returns (address wallet, uint256 assetId, uint256 date, uint256 chainID, uint256 logIndex, bool minted) {
    IncomingLog memory _incoming = incomingTx[_index];
    return (
      _incoming.wallet,
      _incoming.assetId,
      _incoming.date,
      _incoming.chainID,
      _incoming.logIndex,
      _incoming.minted
    );
  }

  function getOutgoingTx(uint256 _index) public view returns (address wallet, uint256 assetId, uint256 date, uint256 chainID, uint256 bridgeIndex) {
    OutgoingLog memory _outgoing = outgoingTx[_index];
    return (
      _outgoing.wallet,
      _outgoing.assetId,
      _outgoing.date,
      _outgoing.chainID,
      _outgoing.bridgeIndex
    );
  }

  function withdrawalCompleted(bytes32 _withdrawalId) public view returns (bool completed) {
    return (withdrawals[_withdrawalId] > 0);
  }

}