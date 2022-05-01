/// SPDX-License-Identifier: AGPL-3.0

// free as in free-for-all

pragma solidity 0.8.13;

import { Dmap } from './dmap.sol';

contract FreeZone {
    Dmap                      public immutable dmap;
    uint256                   public           last;
    mapping(bytes32=>address) public           controllers;

    event Give(address indexed giver, bytes32 indexed zone, address indexed recipient);

    constructor(Dmap d) {
        dmap = d;
    }

    function take(bytes32 key) external {
        require(controllers[key] == address(0), "ERR_TAKEN");
        require(block.timestamp > last, "ERR_LIMIT");
        last = block.timestamp;
        controllers[key] = msg.sender;
        emit Give(address(0), key, msg.sender);
    }

    function give(bytes32 key, address recipient) external {
        require(controllers[key] == msg.sender, "ERR_OWNER");
        controllers[key] = recipient;
        emit Give(msg.sender, key, recipient);
    }

    function set(bytes32 key, bytes32 meta, bytes32 data) external {
        require(controllers[key] == msg.sender, "ERR_OWNER");
        dmap.set(key, meta, data);
    }
}