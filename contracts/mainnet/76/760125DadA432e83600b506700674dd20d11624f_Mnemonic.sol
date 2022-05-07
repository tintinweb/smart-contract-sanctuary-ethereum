// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Mnemonic {
  bytes8[2048] public phrases;

  constructor(bytes8[2048] memory _phrases) {
    phrases = _phrases;
  }

  function bytes8ToString(bytes8 _bytes8) public pure returns (string memory) {
    uint8 i = 0;
    while (i < 8 && _bytes8[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 8 && _bytes8[i] != 0; i++) {
      bytesArray[i] = _bytes8[i];
    }
    return string(bytesArray);
  }

  function get(uint256 _i) public view returns (string memory) {
    return bytes8ToString(phrases[_i]);
  }

  function getMulti(uint256[] memory arr)
    external
    view
    returns (string[] memory)
  {
    string[] memory res = new string[](arr.length);
    for (uint256 i = 0; i < arr.length; i++) {
      res[i] = get(arr[i]);
    }
    return res;
  }

  function random(uint256 _seed, uint256 _n)
    external
    view
    returns (string[] memory values)
  {
    values = new string[](_n);
    uint256 length = phrases.length;
    for (uint256 i = 0; i < _n; i++) {
      values[i] = bytes8ToString(
        phrases[uint256(keccak256(abi.encode(_seed, i))) % length]
      );
    }
    return values;
  }
}