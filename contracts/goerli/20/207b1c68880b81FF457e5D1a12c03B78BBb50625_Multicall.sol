// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma abicoder v2;

contract Multicall {
    function multicall(address target, bytes[] calldata data) public returns (bytes[] memory results) {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, ) = target.staticcall(data[i]);
            require(success, "call failed");
        }
    }
}