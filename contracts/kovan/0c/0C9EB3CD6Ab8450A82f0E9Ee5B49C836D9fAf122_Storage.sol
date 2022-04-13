// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {StorageInterface} from './interfaces/StorageInterface.sol';

contract Storage is StorageInterface {
  mapping(string => string) private _data;

  function set(string memory key, string memory value) public override {
    _data[key] = value;
  }

  function get(string memory key) public view override returns (string memory) {
    return _data[key];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface StorageInterface {
  function set(string memory key, string memory value) external;

  function get(string memory key) external view returns (string memory);
}