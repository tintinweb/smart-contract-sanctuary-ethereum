// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

contract CreateTestA {
    uint256 public argNum;
    address public argAddr;
    string public argStr;

    constructor(uint256 _argNum, address _argAddr, string memory _argStr) {
        argNum = _argNum;
        argAddr = _argAddr;
        argStr = _argStr;
    }
}

contract CreateTestB {
    bytes public argBytes;
    bool public argBool;

    constructor(bytes memory _argBytes, bool _argBool) {
        argBytes = _argBytes;
        argBool = _argBool;
    }
}