//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV1 {
    struct BoxStruct{
        uint256 a;
        uint256 b;
        address c;
    }
    BoxStruct public boxStruct;
    uint8 public constant VAL = 99;
    bool public initialized;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
    }

    function setBoxStruct(uint256 _a, uint256 _b, address _c) external {
        boxStruct.a = _a;
        boxStruct.b = _b;
        boxStruct.c = _c;
    }

    uint256[50] private __gap;
}