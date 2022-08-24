/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
//pragma experimental ABIEncoderV2;

contract PlexiMailRootRegistry {
  
  // struct DeviceEntry {
  //   uint256 registrationId;
  //   uint256 signedPreKeyId;
  //   string signedPrePublicKey;
  //   string signature;
  //   string keyStoreUrl;
  // }

  struct SignalAccount {
    string identityKey;
    string keyStoreUrl;
    string devices;
  }

  mapping (address => SignalAccount) private signalAccounts;
  address private owner;
  
  constructor() {
      owner = msg.sender;
  }

  modifier isOwner() {
    require(tx.origin == owner);
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  function storeKeyBundle(string calldata identityKey, string calldata keyStoreUrl, string calldata devices) public isOwner {
    
    SignalAccount storage account = signalAccounts[msg.sender];
    account.identityKey = identityKey;
    account.keyStoreUrl = keyStoreUrl;
    account.devices = devices;
    signalAccounts[msg.sender] = account;
  }

  function queryKeyBundle(address address_) public view returns (SignalAccount memory) {
    SignalAccount memory account = signalAccounts[address_];
    return account;
  }
}