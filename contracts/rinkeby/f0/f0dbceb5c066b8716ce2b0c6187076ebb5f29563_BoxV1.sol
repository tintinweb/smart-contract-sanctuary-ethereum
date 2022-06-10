//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV1 {

    enum FreshJuiceSize{ SMALL, MEDIUM, LARGE }
    uint64 public ANUMBER;
    FreshJuiceSize public choice;
    bool public initialized;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
        ANUMBER = 999;
    }


    function setChoice(FreshJuiceSize size) external {
        choice = size;
    }

    uint256[50] private __gap;
}