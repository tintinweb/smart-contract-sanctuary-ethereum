// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ABI {
    event Log(bytes);
    event Log(bool);
    event Log(uint256);

    function sum(uint256, uint128) external pure {}

    function bar(bool, uint256) external pure {}

    function baz(
        bool t,
        bytes calldata b,
        uint256 n
    ) external {
        emit Log(t);
        emit Log(b);
        emit Log(n);
    }

    function foo(
        bool t,
        uint256 n,
        bytes calldata b
    ) external {
        emit Log(t);
        emit Log(b);
        emit Log(n);
    }
}