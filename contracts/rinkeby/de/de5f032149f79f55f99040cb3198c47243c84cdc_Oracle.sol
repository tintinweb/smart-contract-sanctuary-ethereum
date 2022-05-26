/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// File: contracts\Oracle.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle {
  address owner;
  uint public rand;

  constructor() {
    owner = msg.sender;
    rand = uint(
      keccak256(
        abi.encodePacked(
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }

  function feedRandomness(uint _rand) external {
    require(
      msg.sender == owner,
      "Owner only"
    );
    
    rand = uint(
      keccak256(
        abi.encodePacked(
          _rand,
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }
}