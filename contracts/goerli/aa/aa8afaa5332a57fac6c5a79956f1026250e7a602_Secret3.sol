/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


/*

In this contract you have to find out private variable to
commit your address to winners array

Unlimit winners
Reward = 3
*/
contract Secret3 {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private time = uint16(block.timestamp);
  bytes32[3] private data;
  address[] hackers;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    hackers.push(msg.sender);
    data[2] = keccak256(abi.encodePacked(_key, msg.sender, block.timestamp));
    ID = block.timestamp;
    flattening = uint8(block.timestamp);
    time = uint16(block.timestamp);
  }

  function getWinners() public view returns(address[] memory) {
    return hackers;
  }
}