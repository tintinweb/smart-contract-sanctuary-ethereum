//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV1 {

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

    modifier onlyOwner(){
        if(msg.sender!=owner) revert("not owner");
        _;
    }

    function incrementVal(uint256 _inc) external onlyOwner {
        val += _inc + 1;
    }

    uint256[50] private __gap;
}