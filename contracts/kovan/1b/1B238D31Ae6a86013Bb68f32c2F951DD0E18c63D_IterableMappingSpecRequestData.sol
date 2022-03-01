// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Job Chainlink Request Data
struct SpecRequestData {
    bytes32 specId;
    address oracle;
    uint256 payment;
    address callbackAddr;
    bytes4 callbackFunctionSignature;
    bool isActive;
    bytes buffer;
}

library IterableMappingSpecRequestData {
    // Iterable mapping from address to SpecRequestData
    struct Map {
        bytes32[] keys; // keccak256(<specId>,<buffer>)
        mapping(bytes32 => SpecRequestData) values;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function get(Map storage map, bytes32 key) public view returns (SpecRequestData memory) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index) public view returns (bytes32) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        bytes32 key,
        SpecRequestData calldata val
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

    function remove(Map storage map, bytes32 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        bytes32 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function removeAll(Map storage map) public {
        for (uint256 i = 0; i < size(map); i++) {
            bytes32 key = getKeyAtIndex(map, i);
            remove(map, key);
        }
    }
}