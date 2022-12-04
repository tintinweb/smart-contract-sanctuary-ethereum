/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library AddressMap {
  struct Map {
    address[] keys;
    mapping(address => bool) values;
    mapping(address => uint) indexOf;
  }

  function get(Map storage map, address key) public view returns (bool) {
    return map.values[key];
  }

  function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
    return map.keys[index];
  }

  function size(Map storage map) public view returns (uint) {
    return map.keys.length;
  }

  function set(
    Map storage map,
    address key
  ) public {
      if (!map.values[key]) {
        map.values[key] = true;
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
      }
  }

  function remove(Map storage map, address key) public {
    if (!map.values[key]) {
      return;
    }

    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}