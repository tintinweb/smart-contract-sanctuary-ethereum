//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV2 {

    address public owner;
    uint256 public val;
    bool public initialized;

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized{
        initialized = true;
        owner = msg.sender;
    }

    modifier onlyOwnerOrLowInc(uint256 _inc){
        if(msg.sender!=owner && _inc<5) revert("not owner or low increment");
        _;
    }

    function incrementVal(uint256 _inc) external onlyOwnerOrLowInc(_inc) {
        val += _inc;
    }

    uint256[50] private __gap;
}