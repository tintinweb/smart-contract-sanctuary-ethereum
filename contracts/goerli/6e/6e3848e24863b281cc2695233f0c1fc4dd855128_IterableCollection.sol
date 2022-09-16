/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableCollection {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => IndexValue) data;
    }

    struct IndexValue {
        uint256 indexOf;
        bool value;
    }

    function keyExists(Map storage map, address key) public view returns (bool) {
        return map.data[key].value;
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function insert(
        Map storage map,
        address key
    ) public {
        if (keyExists(map,key)) {
            return;
        }
        map.data[key] = IndexValue(map.keys.length, true);
        map.keys.push(key);
    }

    function remove(Map storage map, address key) public {
        if (!keyExists(map,key)) {
            return;
        }
        
        //Swap last key with the one to be removed, and then pop the last one
        uint index = map.data[key].indexOf;
        address lastKey = map.keys[map.keys.length - 1];
        map.data[lastKey].indexOf = index;
        
        delete map.data[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}