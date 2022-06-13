//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV2 {
    struct BoxStruct{
        uint256 a;
        uint256 b;
        address c;
        uint256 d;
        uint256 e;
        uint256 f;
        uint256 g;
    }
    uint256 public VAL;
    bool public initialized;
    BoxStruct public boxStruct;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
        VAL = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    }

    function setBoxStruct(uint256 _a, uint256 _b, address _c, uint256 _d, uint256 _e,uint256 _f,uint256 _g) external {
        boxStruct.a = _a;
        boxStruct.b = _b;
        boxStruct.c = _c;
        boxStruct.d = _d;
        boxStruct.e = _e;
        boxStruct.f = _f;
        boxStruct.g = _g;

    }

    uint256[50] private __gap;
}