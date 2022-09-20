// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { Ownable } from "./Ownable.sol";

contract Syncer is Ownable {
  event SyncerAdded(address indexed);
  event SyncerRemoved(address indexed);

  mapping(address => bool) public isSyncer;

  constructor() {
    addSyncer(msg.sender);
  }

  function addSyncer(address _syncer) public onlyOwner {
    isSyncer[_syncer] = true;
    emit SyncerAdded(_syncer);
  }

  function removeSyncer(address _syncer) external onlyOwner {
    isSyncer[_syncer] = false;
    emit SyncerRemoved(_syncer);
  }
}