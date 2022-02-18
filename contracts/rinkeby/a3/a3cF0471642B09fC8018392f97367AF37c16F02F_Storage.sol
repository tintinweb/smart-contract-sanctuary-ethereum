/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.8.9;

contract Storage {
  uint256 public uint256Value;
  bool public boolValue;
  string public stringValue;
  address public addressValue;
  bytes32 public bytes32Value;

  function setStringValue(string memory value) public returns(string memory) {
    stringValue = value;
    return stringValue;
  }

  function setUint256Value(uint256 value) public returns(uint256) {
    uint256Value = value;
    return uint256Value;
  }

  function setBoolValue(bool value) public returns(bool) {
    boolValue = value;
    return boolValue;
  }

  function setAddressValue(address value) public returns(address) {
    addressValue = value;
    return addressValue;
  }

  function setBytes32Value(bytes32 value) public returns(bytes32) {
    bytes32Value = value;
    return bytes32Value;
  }
}