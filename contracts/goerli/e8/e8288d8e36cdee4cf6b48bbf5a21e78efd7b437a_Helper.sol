// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Helper {
  function getChainId() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function getChainName() public view returns (string memory) {
    uint256 id = getChainId();
    if (id == 1) {
      return "mainnet";
    } else if (id == 3) {
      return "ropsten";
    } else if (id == 4) {
      return "rinkeby";
    } else if (id == 5) {
      return "goerli";
    } else if (id == 42) {
      return "kovan";
    } else if (id == 1337) {
      return "localhost";
    } else if (id == 31337) {
      return "localhost";
    } else {
      return "unknown";
    }
  }

  function toString(bytes memory data) public pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < data.length; i++) {
      str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }
}