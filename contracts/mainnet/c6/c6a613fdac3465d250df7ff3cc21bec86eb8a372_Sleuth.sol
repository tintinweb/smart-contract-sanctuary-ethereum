// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Sleuth {

    function query(bytes calldata q) external returns (bytes memory) {
        return queryInternal(q, abi.encodeWithSignature("query()"));
    }

    function query(bytes calldata q, bytes memory c) external returns (bytes memory) {
        return queryInternal(q, c);
    }

    function queryInternal(bytes memory q, bytes memory c) internal returns (bytes memory) {
        assembly {
            let queryLen := mload(q)
            let queryStart := add(q, 0x20)
            let deployment := create(0, queryStart, queryLen)
            let callLen := mload(c)
            let callStart := add(c, 0x20)
            pop(call(gas(), deployment, 0, callStart, callLen, 0xc0, 0))
            returndatacopy(0xc0, 0, returndatasize())
            mstore(0x80, 0x20)
            mstore(0xa0, returndatasize())
            let sz := add(returndatasize(), 0x40)
            return(0x80, sz)
        }
    }
}