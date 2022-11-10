// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library IterableMapping {
    // Iterable mapping from address to uint256;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
    }

    function get(Map storage self, address key) public view returns (uint256) {
        return self.values[key];
    }

    function getKeyAtIndex(
        Map storage self,
        uint256 index
    ) public view returns (address) {
        return self.keys[index];
    }

    function size(Map storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function set(Map storage self, address key, uint256 val) public {
        if (self.values[key] == 0 && val != 0) self.keys.push(key);

        self.values[key] = val;
    }

    function increment(Map storage self, address key, uint256 val) public {
        if (self.values[key] == 0 && val != 0) self.keys.push(key);

        self.values[key] += val;
    }
}