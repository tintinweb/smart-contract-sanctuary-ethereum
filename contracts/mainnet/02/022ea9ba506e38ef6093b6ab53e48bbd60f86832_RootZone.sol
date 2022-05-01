/// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.13;

import { Dmap } from './dmap.sol';

contract RootZone {
    Dmap    public immutable dmap;
    uint256 public           last;
    bytes32 public           mark;
    uint256        immutable FREQ = 31 hours;
    bytes32        immutable LOCK = bytes32(uint(0x1));

    event Hark(bytes32 indexed mark);
    event Etch(bytes32 indexed name, address indexed zone);

    error ErrPending();
    error ErrExpired();
    error ErrPayment();
    error ErrReceipt();

    constructor(Dmap d) {
        dmap = d;
    }

    function hark(bytes32 hash) external payable {
        if (block.timestamp < last + FREQ) revert ErrPending();
        if (msg.value != 1 ether) revert ErrPayment();
        (bool ok, ) = block.coinbase.call{value:(10**18)}("");
        if (!ok) revert ErrReceipt();
        last = block.timestamp;
        mark = hash;
        emit Hark(mark);
    }

    function etch(bytes32 salt, bytes32 name, address zone) external {
        bytes32 hash = keccak256(abi.encode(salt, name, zone));
        if (hash != mark) revert ErrExpired();
        dmap.set(name, LOCK, bytes32(bytes20(zone)));
        emit Etch(name, zone);
    }
}