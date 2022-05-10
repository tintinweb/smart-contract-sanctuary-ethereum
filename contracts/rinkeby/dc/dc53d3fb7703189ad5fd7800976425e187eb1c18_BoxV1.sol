//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV1 {
    struct BoxStruct{
        uint256 a;
        uint256 b;
        address c;
    }
    BoxStruct public boxStruct;
    uint256 public VAL;
    bool public initialized;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
        VAL = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    }

    function setBoxStruct(uint256 _a, uint256 _b, address _c) external {
        boxStruct.a = _a;
        boxStruct.b = _b;
        boxStruct.c = _c;
    }

    uint256[50] private __gap;
}