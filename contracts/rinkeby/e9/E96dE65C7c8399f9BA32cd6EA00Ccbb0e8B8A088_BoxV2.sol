//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV2 {
    struct BoxStruct{
        uint256 a;
        uint256 b;
        address c;
        uint256 d;
    }
    BoxStruct public boxStruct;
    uint256 public constant VAL = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    bool public initialized;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
    }

    function setBoxStruct(uint256 _a, uint256 _b, address _c, uint256 _d) external {
        boxStruct.a = _a;
        boxStruct.b = _b;
        boxStruct.c = _c;
        boxStruct.d = _d;
    }

    uint256[50] private __gap;
}