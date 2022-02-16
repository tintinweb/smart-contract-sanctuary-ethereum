// SPDX-License-Identifier: MIT

// from https://solidity-by-example.org/app/iterable-mapping/
pragma solidity ^0.8.0;

struct Stake {
    address account_owner;
    uint256 timestamp;
    uint256 stake;
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        uint256[] keys;
        mapping(uint256 => Stake) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 stake_id)
        public
        view
        returns (Stake memory)
    {
        return map.values[stake_id];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (uint256)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        uint256 stake_id,
        Stake memory stake
    ) public {
        if (map.inserted[stake_id]) {
            map.values[stake_id] = stake;
        } else {
            map.inserted[stake_id] = true;
            map.values[stake_id] = stake;
            map.indexOf[stake_id] = map.keys.length;
            map.keys.push(stake_id);
        }
    }

    function empty(Map storage map) public view returns (bool) {
        return size(map) == 0;
    }

    function remove(Map storage map, uint256 stake_id) public {
        if (!map.inserted[stake_id]) {
            return;
        }

        delete map.inserted[stake_id];
        delete map.values[stake_id];

        uint256 index = map.indexOf[stake_id];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[stake_id];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}