/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

pragma solidity ^0.5.0;

contract NotSoPriv8 {

  bytes32 private key;
  bool public locked = true;

  constructor(bytes32 _key) public {
    key = _key;
  }

  function own(bytes32 _key) public {
    if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(_key))) {
      locked = false;
    }
  }

}