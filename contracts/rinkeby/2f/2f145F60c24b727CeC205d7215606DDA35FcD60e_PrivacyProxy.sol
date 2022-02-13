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
}

contract PrivacyProxy {
  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }

  function unlock(address privacy, bytes16 _key) public {
    (bool success, ) = privacy.delegatecall(
      abi.encodeWithSignature("unlock(bytes16)", _key)
    );
    require(success, "failed to unlock");
  }
}

contract AttackPrivacy {
  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }

  function unlock(
    PrivacyProxy proxy,
    address privacy,
    bytes16 _key
  ) public {
    proxy.unlock(privacy, _key);
  }

  function isSame(bytes16 b16, bytes32 b32) public pure returns (bool) {
    return b16 == bytes16(b32);
  }
}