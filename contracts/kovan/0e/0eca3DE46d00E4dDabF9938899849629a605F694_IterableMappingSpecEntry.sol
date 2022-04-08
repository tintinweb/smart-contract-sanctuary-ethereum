// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct RequestData {
    bytes32 specId;
    address oracle;
    uint256 payment;
    address callbackAddr;
    bytes4 callbackFunctionSignature;
    bytes buffer;
}

struct Schedule {
    uint128 startAt;
    uint128 interval;
}

error SpecEntryNotInserted(bytes32 key);

library IterableMappingSpecEntry {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => RequestData) requestData;
        mapping(bytes32 => Schedule) schedule;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
        mapping(bytes32 => bool) inactive;
        mapping(bytes32 => uint256) lastRequestTimestamp;
    }

    function getInactive(Map storage _map, bytes32 _key) public view returns (bool) {
        return _map.inactive[_key];
    }

    function getLastRequestTimestamp(Map storage _map, bytes32 _key) public view returns (uint256) {
        return _map.lastRequestTimestamp[_key];
    }

    function getRequestData(Map storage _map, bytes32 _key) public view returns (RequestData memory) {
        return _map.requestData[_key];
    }

    function getSchedule(Map storage _map, bytes32 _key) public view returns (Schedule memory) {
        return _map.schedule[_key];
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
            revert SpecEntryNotInserted(_key);
        }

        delete _map.inserted[_key];
        delete _map.inactive[_key];
        delete _map.requestData[_key];
        delete _map.schedule[_key];
        delete _map.lastRequestTimestamp[_key];

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

    function set(
        Map storage _map,
        bytes32 _key,
        bool _inactive,
        uint256 _lastRequestTimestamp,
        RequestData calldata _requestData,
        Schedule calldata _schedule
    ) public {
        if (!_map.inserted[_key]) {
            _map.inserted[_key] = true;
            _map.indexOf[_key] = _map.keys.length;
            _map.keys.push(_key);
        }
        _map.requestData[_key] = _requestData;
        _map.schedule[_key] = _schedule;
        _map.inactive[_key] = _inactive;
        _map.lastRequestTimestamp[_key] = _lastRequestTimestamp;
    }

    function setInactive(
        Map storage _map,
        bytes32 _key,
        bool _inactive
    ) public {
        if (!_map.inserted[_key]) {
            revert SpecEntryNotInserted(_key);
        }
        _map.inactive[_key] = _inactive;
    }

    function setLastRequestTimestamp(
        Map storage _map,
        bytes32 _key,
        uint256 _timestamp
    ) public {
        if (!_map.inserted[_key]) {
            revert SpecEntryNotInserted(_key);
        }
        _map.lastRequestTimestamp[_key] = _timestamp;
    }

    function setRequestData(
        Map storage _map,
        bytes32 _key,
        RequestData calldata _requestData
    ) public {
        if (!_map.inserted[_key]) {
            revert SpecEntryNotInserted(_key);
        }
        _map.requestData[_key] = _requestData;
    }

    function setSchedule(
        Map storage _map,
        bytes32 _key,
        Schedule calldata _schedule
    ) public {
        if (!_map.inserted[_key]) {
            revert SpecEntryNotInserted(_key);
        }
        _map.schedule[_key] = _schedule;
    }
}