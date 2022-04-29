// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct SpecEntry {
    bytes32 specId;
    address oracle;
    uint256 payment;
    address callbackAddr;
    uint128 startAt;
    uint128 interval;
    bool inactive;
    bytes4 callbackFunctionSignature;
    bytes buffer;
}

error IterableMappingSpecEntry2__SpecEntryNotInserted(bytes32 key);

library IterableMappingSpecEntry2 {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => SpecEntry) specEntries;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function getSpecEntry(Map storage _map, bytes32 _key) public view returns (SpecEntry memory) {
        return _map.specEntries[_key];
    }

    function getKeyAtIndex(Map storage _map, uint256 _index) public view returns (bytes32) {
        return _map.keys[_index];
    }

    function isInserted(Map storage _map, bytes32 _key) public view returns (bool) {
        return _map.inserted[_key];
    }

    function size(Map storage _map) public view returns (uint256) {
        return _map.keys.length;
    }

    function remove(Map storage _map, bytes32 _key) public {
        if (!_map.inserted[_key]) {
            revert IterableMappingSpecEntry2__SpecEntryNotInserted(_key);
        }

        delete _map.inserted[_key];
        delete _map.specEntries[_key];

        uint256 index = _map.indexOf[_key];
        uint256 lastIndex = _map.keys.length - 1;
        bytes32 lastKey = _map.keys[lastIndex];

        _map.indexOf[lastKey] = index;
        delete _map.indexOf[_key];

        _map.keys[index] = lastKey;
        _map.keys.pop();
    }

    function removeAll(Map storage _map) public {
        uint256 mapSize = size(_map);
        for (uint256 i = 0; i < mapSize; ) {
            bytes32 key = getKeyAtIndex(_map, 0);
            remove(_map, key);
            unchecked {
                ++i;
            }
        }
    }

    function setSpecEntry(
        Map storage _map,
        bytes32 _key,
        SpecEntry calldata _specEntry
    ) public {
        if (!_map.inserted[_key]) {
            _map.inserted[_key] = true;
            _map.indexOf[_key] = _map.keys.length;
            _map.keys.push(_key);
        }
        _map.specEntries[_key] = _specEntry;
    }
}