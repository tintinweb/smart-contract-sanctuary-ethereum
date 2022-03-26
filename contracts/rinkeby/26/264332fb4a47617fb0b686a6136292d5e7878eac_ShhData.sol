/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

pragma solidity ^0.4.24;

contract ShhData {

  address public owner;
  mapping(address => string) shhKeyIdMap;
  mapping(address => bytes32) shhPriKeyMap;
  mapping(address => string) public shhPubKeyMap;
  mapping(address => string) public shhNameMap;

  constructor() public {
    owner = msg.sender;
  }

  function saveShhKey(string shhKeyId, bytes32 shhPriKey, string shhPubKey) public returns (bool success) {
    shhKeyIdMap[msg.sender] = shhKeyId;
    shhPriKeyMap[msg.sender] = shhPriKey;
    shhPubKeyMap[msg.sender] = shhPubKey;
    return true;
  }

  function saveShhKeyId(string shhKeyId) public returns (bool success) {
    shhKeyIdMap[msg.sender] = shhKeyId;
    return true;
  }

  function saveShhKeyPriKey(bytes32 shhPriKey) public returns (bool success) {
    shhPriKeyMap[msg.sender] = shhPriKey;
    return true;
  }

  function saveShhPubKey(string shhPubKey) public returns (bool success) {
    shhPubKeyMap[msg.sender] = shhPubKey;
    return true;
  }

  function saveShhName(string shhName) public returns (bool success) {
    shhNameMap[msg.sender] = shhName;
    return true;
  }

  function getShhKeyId() public returns(string keyId) {
    return shhKeyIdMap[msg.sender];
  }

  function getShhPriKey() public returns(bytes32 priKey) {
    return shhPriKeyMap[msg.sender];
  }

  function getShhPubKey() public returns(string pubKey) {
    return shhPubKeyMap[msg.sender];
  }

  function getPublicShhPubKey(address adr) public returns(string pubKey) {
    return shhPubKeyMap[adr];
  }

  function getPublicShhName(address adr) public returns(string shhName) {
    return shhNameMap[adr];
  }
}