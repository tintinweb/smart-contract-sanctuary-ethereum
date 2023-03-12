// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice Library to allow iteration of an ordered mapping of address -> uint
library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    /// @notice Gets the index in the mapping of the specified key
    /// @param map The map to find the key in
    /// @param key The key to get the index for
    /// @return index The index of the key that was passed in
    function getIndexOfKey(Map storage map, address key) public view returns (int index) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    /// @notice Get the key and a specific index
    /// @param map The map to get the key from
    /// @param index The index to retrieve the key from
    /// @param key The address(key) of the index passed in
    function getKeyAtIndex(Map storage map, uint index) public view returns (address key) {
        return map.keys[index];
    }

    /// @notice Gets the size of the map
    /// @return mapSize The size of the map
    function size(Map storage map) public view returns (uint mapSize) {
        return map.keys.length;
    }

    /// @notice Sets a key/value pair into the map
    /// @param map The map to add to
    /// @param key The address to key the value on
    /// @param val The value associated with the key
    function set(
        Map storage map,
        address key,
        uint val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    /// @notice Removes a key/value form the map
    /// @param map The map to remove the entry from
    /// @param key The key of the entry to remove from the map
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
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