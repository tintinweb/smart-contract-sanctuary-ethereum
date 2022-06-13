//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Base{
    uint256 public val;
    uint256 public newVariable;
    mapping(uint256 => uint256) public newMapping;
    uint256[] public newArray;

    
    uint256[7] private __gap;
}

contract BoxV2 is Base {

    address public owner;
    bool public initialized;

    modifier checkInitialized() {
        if(initialized) revert("Already initialized");
        _;
    }

    function init() external checkInitialized {
        initialized = true;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender!=owner) revert("not owner");
        _;
    }

    function incrementVal(uint256 _inc) external onlyOwner {
        val += _inc;
    }

    function setNewVariable(uint256 _newVariable) external {
        newVariable = _newVariable;
    }

    function setNewMapping(uint256 index, uint256 _val) external {
        newMapping[index] = _val;
    }

    uint256[47] private __gap;
}