// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library IterableMapping {
    // Iterable mapping from address to balances;
    struct Map {
        address[] keys;
        mapping(address => Value) values;
        mapping(address => uint256) indexOf;
    }

    struct Value {
        uint256 stk;
        uint256 eth;
    }

    function get(
        Map storage self,
        address _key
    ) public view returns (uint256 eth, uint256 stk) {
        return (self.values[_key].eth, self.values[_key].stk);
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

    function increment(
        Map storage self,
        address _key,
        uint256 _eth,
        uint256 _stk
    ) public {
        if (self.values[_key].stk == 0 && self.values[_key].stk == 0) {
            self.indexOf[_key] = self.keys.length;
            self.keys.push(_key);
        }

        self.values[_key].eth += _eth;
        self.values[_key].stk += _stk;
    }

    function remove(Map storage self, address _key) public {
        if (self.values[_key].stk == 0 && self.values[_key].stk == 0) {
            return;
        }

        delete self.values[_key];

        uint256 index = self.indexOf[_key];
        uint256 lastIndex = self.keys.length - 1;
        address lastKey = self.keys[lastIndex];

        self.indexOf[lastKey] = index;
        delete self.indexOf[_key];

        self.keys[index] = lastKey;
        self.keys.pop();
    }
}