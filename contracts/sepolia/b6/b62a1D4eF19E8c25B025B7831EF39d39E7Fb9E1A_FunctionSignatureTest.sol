// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title A simple smart contract to test the gas savings from optimizing 4-byte function signatures.
contract FunctionSignatureTest {
    function f(uint256) external pure {} // 0xb3de648b
    function f_17(uint256) external pure {} // 0x0042aabc
    function f_oOq(uint256) external pure {} // 0x0000e0f0
    function f2_bz3g(uint256) external pure {} // 0x00000053
    function f1_aE3j(uint256) external pure {} // 0x00000006
}