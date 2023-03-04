// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CodeHash {
    function erc1167codeHash(address implementation) public pure returns (bytes32 result) {
        assembly {
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x363d3d373d3d3d363d73000000))
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            result := keccak256(0x13, 0x2d)
        }
    }

    function codeHash(address addr) public view returns (bytes32 result) {
        result = keccak256(addr.code);
    }
}