// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract Implementation {
    event Log(uint256 x, uint256 y, uint256 sum);

    address public implementation;

    function addAndEmit(uint256 x, uint256 y) external {
        emit Log(x, y, x + y);
    }

    function getFuncData(uint256 x, uint256 y) external view returns (bytes memory) {
        return abi.encodeCall(this.addAndEmit, (x, y));
    }
}