/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

/// SPDX-License-Identifier: AGPL-3.0

// One day, someone is going to try very hard to prevent you
// from accessing one of these storage slots.

pragma solidity 0.8.13;

interface Dmap {
    error LOCKED();
    event Set(
        address indexed zone,
        bytes32 indexed name,
        bytes32 indexed meta,
        bytes32 indexed data
    ) anonymous;

    function set(bytes32 name, bytes32 meta, bytes32 data) external;
    function get(bytes32 slot) external view returns (bytes32 meta, bytes32 data);
}

contract _dmap_ {
    error LOCKED();
    uint256 constant LOCK = 0x1;
    constructor(address rootzone) { assembly {
        sstore(0, LOCK)
        sstore(1, shl(96, rootzone))
    }}
    fallback() external payable { assembly {
        if eq(36, calldatasize()) {
            mstore(0, sload(calldataload(4)))
            mstore(32, sload(add(1, calldataload(4))))
            return(0, 64)
        }
        let name := calldataload(4)
        let meta := calldataload(36)
        let data := calldataload(68)
        mstore(0, caller())
        mstore(32, name)
        let slot := keccak256(0, 64)
        log4(0, 0, caller(), name, meta, data)
        sstore(add(slot, 1), data)
        if iszero(or(xor(100, calldatasize()), and(LOCK, sload(slot)))) {
            sstore(slot, meta)
            return(0, 0)
        }
        if eq(100, calldatasize()) {
            mstore(0, shl(224, 0xa1422f69))
            revert(0, 4)
        }
        revert(0, 0)
    }}
}