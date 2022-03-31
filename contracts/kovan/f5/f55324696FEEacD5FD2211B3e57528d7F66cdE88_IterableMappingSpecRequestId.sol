// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error SpecRequestIdNotInserted(bytes32 key);

library IterableMappingSpecRequestId {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => bytes32) requestId;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function get(Map storage _map, bytes32 _key) public view returns (bytes32) {
        return _map.requestId[_key];
    }

    function getKeyAtIndex(Map storage _map, uint256 _index) public view returns (bytes32) {
        return _map.keys[_index];
    }

    function size(Map storage _map) public view returns (uint256) {
        return _map.keys.length;
    }

    function set(
        Map storage _map,
        bytes32 _key,
        bytes32 _val
    ) public {
        if (!_map.inserted[_key]) {
            _map.inserted[_key] = true;
            _map.indexOf[_key] = _map.keys.length;
            _map.keys.push(_key);
        }
        _map.requestId[_key] = _val;
    }

    function remove(Map storage _map, bytes32 _key) public {
        if (!_map.inserted[_key]) {
            revert SpecRequestIdNotInserted(_key);
        }

        delete _map.inserted[_key];
        delete _map.requestId[_key];

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
}